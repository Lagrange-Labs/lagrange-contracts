pragma solidity =0.8.12;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import {IStrategy} from "eigenlayer-contracts/interfaces/IStrategy.sol";
import {ISlasher} from "eigenlayer-contracts/interfaces/ISlasher.sol";
import {IDelegationTerms} from "eigenlayer-contracts/interfaces/IDelegationTerms.sol";
import {DelegationManager} from "eigenlayer-contracts/core/DelegationManager.sol";
import {StrategyManager} from "eigenlayer-contracts/core/StrategyManager.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO: referecen the deploy script

contract RegisterOperator is Script, Test {
    string public deployDataPath =
        string(bytes("script/output/M1_deployment_data.json"));
    string public deployLGRPath =
        string(bytes("script/output/deployed_lgr.json"));

    bytes4 public constant WETH_DEPOSIT_SELECTOR =
        bytes4(keccak256(bytes("deposit()")));

    function run() public {
        vm.startBroadcast(msg.sender);

        string memory deployData = vm.readFile(deployDataPath);

        address WETHStractegyAddress = stdJson.readAddress(
            deployData,
            ".addresses.strategies.['Wrapped Ether']"
        );
        IStrategy WETHStrategy = IStrategy(WETHStractegyAddress);

        IERC20 WETH = WETHStrategy.underlyingToken();

        // send 1e19 wei to the WETH contract to get WETH
        (bool success, ) = address(WETH).call{value: 1e19}(
            abi.encodeWithSelector(WETH_DEPOSIT_SELECTOR)
        );
        require(success, "WETH deposit failed");

        // approve strategy manager to spend WETH
        StrategyManager strategyManager = StrategyManager(
            stdJson.readAddress(deployData, ".addresses.strategyManager")
        );
        console.log("StrategyManager", address(strategyManager));

        WETH.approve(address(strategyManager), 1e30);
        console.log("WETH approved.");
        
        // deposit 1e17 WETH into strategy
        strategyManager.depositIntoStrategy(WETHStrategy, WETH, 1e17);

        DelegationManager delegation = DelegationManager(
            stdJson.readAddress(deployData, ".addresses.delegation")
        );
        delegation.registerAsOperator(IDelegationTerms(msg.sender));

        vm.stopBroadcast();
    }
}