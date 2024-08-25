// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console, Vm} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {TransferUSDC} from "src/TransferUSDC.sol";
import {SwapTestnetUSDC} from "src/SwapTestnetUSDC.sol";
import {CrossChainReceiver} from "src/CrossChainReceiver.sol";
import "script/Helper.sol";

contract EstimateCCIPReceiveGas is Test, Helper {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    TransferUSDC public transferUSDC;
    SwapTestnetUSDC public swapTestnetUSDC;
    CrossChainReceiver public crossChainReceiver;
    uint256 public ethSepoliaFork;
    uint256 public avaxFujiFork;
    Register.NetworkDetails ethSepoliaNetworkDetails;
    Register.NetworkDetails avaxFujiNetworkDetails;
    address constant tester = 0xFB0c1e0a4deD6DF74E5CAa07924aa3F8272Ad0B8;
    address constant sepFauceteer = 0x68793eA49297eB75DFB4610B68e076D2A5c7646C;
    address constant sepCometAddress =
        0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;

    function setUp() public {
        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString(
            "ETHEREUM_SEPOLIA_RPC_URL"
        );
        string memory AVALANCHE_FUJI_RPC_URL = vm.envString(
            "AVALANCHE_FUJI_RPC_URL"
        );
        ethSepoliaFork = vm.createFork(ETHEREUM_SEPOLIA_RPC_URL);
        avaxFujiFork = vm.createSelectFork(AVALANCHE_FUJI_RPC_URL); // set network to fuji

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        assertEq(vm.activeFork(), avaxFujiFork); // sanity check
        // Fetch network details
        avaxFujiNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        assertEq(avaxFujiNetworkDetails.chainSelector, 14767482510784806043); // sanity check

        vm.prank(tester);
        // Deploy TransferUSDC to Avalanche Fuji
        transferUSDC = new TransferUSDC(
            routerAvalancheFuji,
            linkAvalancheFuji,
            usdcAvalancheFuji
        );

        vm.selectFork(ethSepoliaFork); // switch network to eth sepolia
        assertEq(vm.activeFork(), ethSepoliaFork); // sanity check
        // Fetch network details
        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        assertEq(ethSepoliaNetworkDetails.chainSelector, 16015286601757825753); // sanity check

        vm.startPrank(tester);

        // Deploy SwapTestnetUSDC on Sepolia
        swapTestnetUSDC = new SwapTestnetUSDC(
            usdcEthereumSepolia,
            usdcEthereumSepolia,
            sepFauceteer
        );

        // Deploy CrossChainReceiver on Sepolia
        crossChainReceiver = new CrossChainReceiver(
            routerEthereumSepolia,
            sepCometAddress,
            address(swapTestnetUSDC)
        );

        vm.stopPrank();

        vm.selectFork(avaxFujiFork); // switch network to fuji
        assertEq(vm.activeFork(), avaxFujiFork); // sanity check

        vm.prank(tester);
        // allow  list eth sepolia as dest chain in TransferUSDC on fuji
        transferUSDC.allowlistDestinationChain(
            ethSepoliaNetworkDetails.chainSelector,
            true
        );

        // Fund TransferUSDC 3 LINK on fuji
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(transferUSDC), 3 ether);

        vm.prank(tester);
        // approve TransferUSDC to spend 1 USDC
        IERC20(usdcAvalancheFuji).approve(address(transferUSDC), 1_000_000);

        vm.selectFork(ethSepoliaFork); // switch network to eth sepolia
        assertEq(vm.activeFork(), ethSepoliaFork); // sanity check

        vm.prank(tester);
        // allow  list fuji as source chain in CrossChainReceiver on eth sepolia
        crossChainReceiver.allowlistSourceChain(
            avaxFujiNetworkDetails.chainSelector,
            true
        );
    }

    function test_transferUSDC() public {
        vm.recordLogs(); // Starts recording logs to capture events.

        vm.selectFork(avaxFujiFork); // switch network to fuji
        assertEq(vm.activeFork(), avaxFujiFork); // sanity check

        vm.prank(tester);
        transferUSDC.transferUsdc(
            ethSepoliaNetworkDetails.chainSelector,
            address(crossChainReceiver),
            1_000_000,
            500_000
        );

        ccipLocalSimulatorFork.switchChainAndRouteMessage(ethSepoliaFork);
        assertEq(IERC20(usdcEthereumSepolia).balanceOf(address(crossChainReceiver)), 1_000_000);

        // Fetches recorded logs to check for specific events and their outcomes.
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MsgExecuted(bool,bytes,uint256)"
        );

        for (uint i = 0; i < logs.length; ) {
            if (logs[i].topics[0] == msgExecutedSignature) {
                (, , uint256 gasUsed) = abi.decode(
                    logs[i].data,
                    (bool, bytes, uint256)
                );
                console.log("Gas used: %d", gasUsed);
            }
            ++i;
        }
    }
}
