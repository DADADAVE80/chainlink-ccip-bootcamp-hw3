// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console, Vm} from "forge-std/Test.sol";
// import {CCIPLocalSimulator, IRouterClient, WETH9, LinkToken, BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
// import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
// import {TransferUSDC} from "../../src/TransferUSDC.sol";

// // import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
// // import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
// // import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

// contract EstimateCCIPReceiveGas is Test {
//     CCIPLocalSimulator public ccipLocalSimulator;
//     TransferUSDC public transferUSDC;
//     address public alice;
//     address public bob;
//     uint64 public destinationChainSelector;
//     LinkToken linkToken;
//     BurnMintERC677Helper public usdcToken;

//     function setUp() public {
//         ccipLocalSimulator = new CCIPLocalSimulator();

//         (
//             uint64 chainSelector,
//             IRouterClient sourceRouter,
//             IRouterClient destinationRouter,
//             WETH9 wrappedNative,
//             LinkToken link,
//             BurnMintERC677Helper ccipBnM,
//             BurnMintERC677Helper ccipLnM
//         ) = ccipLocalSimulator.configuration();

//         transferUSDC = new TransferUSDC(
//             sourceRouter.address,
//             link.address,
//             usdcToken.address
//         );

//         bob = makeAddr("bob");
//         alice = makeAddr("alice");
//     }

//     function prepareScenario()
//         public
//         returns (
//             Client.EVMTokenAmount[] memory tokensToSendDetails,
//             uint256 amountToSend
//         )
//     {
//         vm.selectFork(sourceFork);
//         vm.startPrank(alice);
//         sourceCCIPBnMToken.drip(alice);

//         amountToSend = 100;
//         sourceCCIPBnMToken.approve(address(sourceRouter), amountToSend);

//         tokensToSendDetails = new Client.EVMTokenAmount[](1);
//         tokensToSendDetails[0] = Client.EVMTokenAmount({
//             token: address(sourceCCIPBnMToken),
//             amount: amountToSend
//         });

//         vm.stopPrank();
//     }

//     function test_transferTokensFromEoaToEoaPayFeesInLink() external {
//         (
//             Client.EVMTokenAmount[] memory tokensToSendDetails,
//             uint256 amountToSend
//         ) = prepareScenario();
//         vm.selectFork(destinationFork);
//         uint256 balanceOfBobBefore = destinationCCIPBnMToken.balanceOf(bob);

//         vm.selectFork(sourceFork);
//         uint256 balanceOfAliceBefore = sourceCCIPBnMToken.balanceOf(alice);
//         ccipLocalSimulatorFork.requestLinkFromFaucet(alice, 10 ether);

//         vm.startPrank(alice);
//         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
//             receiver: abi.encode(bob),
//             data: abi.encode(""),
//             tokenAmounts: tokensToSendDetails,
//             extraArgs: Client._argsToBytes(
//                 Client.EVMExtraArgsV1({gasLimit: 0})
//             ),
//             feeToken: address(sourceLinkToken)
//         });

//         uint256 fees = sourceRouter.getFee(destinationChainSelector, message);
//         sourceLinkToken.approve(address(sourceRouter), fees);
//         sourceRouter.ccipSend(destinationChainSelector, message);
//         vm.stopPrank();

//         uint256 balanceOfAliceAfter = sourceCCIPBnMToken.balanceOf(alice);
//         assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);

//         ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
//         uint256 balanceOfBobAfter = destinationCCIPBnMToken.balanceOf(bob);
//         assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
//     }

//     function test_transferTokensFromEoaToEoaPayFeesInNative() external {
//         (
//             Client.EVMTokenAmount[] memory tokensToSendDetails,
//             uint256 amountToSend
//         ) = prepareScenario();
//         vm.selectFork(destinationFork);
//         uint256 balanceOfBobBefore = destinationCCIPBnMToken.balanceOf(bob);

//         vm.selectFork(sourceFork);
//         uint256 balanceOfAliceBefore = sourceCCIPBnMToken.balanceOf(alice);

//         vm.startPrank(alice);
//         deal(alice, 5 ether);

//         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
//             receiver: abi.encode(bob),
//             data: abi.encode(""),
//             tokenAmounts: tokensToSendDetails,
//             extraArgs: Client._argsToBytes(
//                 Client.EVMExtraArgsV1({gasLimit: 0})
//             ),
//             feeToken: address(0)
//         });

//         uint256 fees = sourceRouter.getFee(destinationChainSelector, message);
//         sourceRouter.ccipSend{value: fees}(destinationChainSelector, message);
//         vm.stopPrank();

//         uint256 balanceOfAliceAfter = sourceCCIPBnMToken.balanceOf(alice);
//         assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);

//         ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
//         uint256 balanceOfBobAfter = destinationCCIPBnMToken.balanceOf(bob);
//         assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
//     }
// }
