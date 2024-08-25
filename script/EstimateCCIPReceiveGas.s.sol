// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Importing necessary components from the Chainlink and Forge Standard libraries for testing.
import {Script, console, VmSafe} from "forge-std/Script.sol";
import "./Helper.sol";
import {TransferUSDC} from "../src/TransferUSDC.sol";
import {SwapTestnetUSDC} from "../src/SwapTestnetUSDC.sol";
import {CrossChainReceiver} from "../src/CrossChainReceiver.sol";

contract TransferUsdcFromFujiToSep is Script, Helper {
    TransferUSDC transferUSDC;

    function run() external {
        vm.startBroadcast();
        transferUSDC = new TransferUSDC(
            routerAvalancheFuji,
            linkAvalancheFuji,
            usdcAvalancheFuji
        );
        console.log("TransferUSDC address: ", address(transferUSDC));

        (bool linkTrfSuccess, ) = address(linkAvalancheFuji).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(transferUSDC),
                3_000_000_000_000_000_000
            )
        );

        if (linkTrfSuccess) console.log("Link transfer successful");

        (bool usdcApprSuccess, ) = address(usdcAvalancheFuji).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(transferUSDC),
                1_000_000
            )
        );

        if (usdcApprSuccess) console.log("USDC approval successful");

        transferUSDC.allowlistDestinationChain(chainIdEthereumSepolia, true);

        transferUSDC.transferUsdc(
            chainIdEthereumSepolia,
            msg.sender,
            1_000_000,
            0 // EOAs don't require gas fees to recieve tokens
        );

        console.log("Message sender: ", msg.sender);

        vm.stopBroadcast();
    }
}

contract DeploySwapTestnetUSDCandCrossChainReceiverOnSep is Script, Helper {
    SwapTestnetUSDC swapTestnetUSDC;
    CrossChainReceiver crossChainReceiver;
    address constant fauceteer = 0x68793eA49297eB75DFB4610B68e076D2A5c7646C;
    address constant cometAddress = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;

    function run(address _transferUsdcAddr) external {
        vm.startBroadcast();

        swapTestnetUSDC = new SwapTestnetUSDC(
            usdcEthereumSepolia,
            usdcEthereumSepolia,
            fauceteer
        );

        crossChainReceiver = new CrossChainReceiver(
            routerEthereumSepolia,
            cometAddress,
            address(swapTestnetUSDC)
        );
        console.log(
            "CrossChainReceiver address: ",
            address(crossChainReceiver)
        );

        crossChainReceiver.allowlistSourceChain(chainIdAvalancheFuji, true);

        crossChainReceiver.allowlistSender(_transferUsdcAddr, true);

        vm.stopBroadcast();
    }
}

contract TransferUsdcFromFujiToCompOnSep is Script, Helper {
    function run(
        address _transferUsdcAddr,
        address _crossChainReceiver
    ) external {
        vm.startBroadcast();
        vm.recordLogs(); // Starts recording logs to capture events.

        (bool usdcApprSuccess, ) = address(usdcAvalancheFuji).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                _transferUsdcAddr,
                1_000_000
            )
        );

        if (usdcApprSuccess) console.log("USDC approval successful");

        TransferUSDC(_transferUsdcAddr).transferUsdc(
            chainIdEthereumSepolia,
            address(_crossChainReceiver),
            1_000_000,
            50000 // ccipRecieve estimate gas (5190) +10%
        );

        // Fetches recorded logs to check for specific events and their outcomes.
        VmSafe.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MsgExecuted(bool,bytes,uint256)"
        );

        for (uint i = 0; i < logs.length; ) {
            if (logs[i].topics[0] == msgExecutedSignature) {
                (, , uint256 gasUsed) = abi.decode(
                    logs[i].data,
                    (bool, bytes, uint256)
                );
                console.log(
                    "Gas used: %d",
                    gasUsed
                );
            }
            ++i;
        }

        vm.stopBroadcast();
    }
}
