pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISlasher} from "eigenlayer-contracts/interfaces/ISlasher.sol";
import {IStrategyManager} from "eigenlayer-contracts/interfaces/IStrategyManager.sol";
import {IServiceManager} from "eigenlayer-contracts/interfaces/IServiceManager.sol";
import {EmptyContract} from "eigenlayer-contracts-test/mocks/EmptyContract.sol";

import {LagrangeService} from "src/protocol/LagrangeService.sol";
import {LagrangeServiceManager} from "src/protocol/LagrangeServiceManager.sol";
import {LagrangeCommittee} from "src/protocol/LagrangeCommittee.sol";

import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract Deploy is Script, Test {
    string public deployDataPath =
        string(bytes("script/output/M1_deployment_data.json"));
    string public poseidonDataPath =
        string(bytes("util/output/poseidonAddresses.json"));
    string public serviceDataPath =
        string(bytes("config/LagrangeService.json"));

    address slasherAddress;
    address strategyManagerAddress;

    // Lagrange Contracts
    ProxyAdmin public proxyAdmin;
    LagrangeCommittee public lagrangeCommittee;
    LagrangeCommittee public lagrangeCommitteeImp;
    LagrangeService public lagrangeService;
    LagrangeService public lagrangeServiceImp;
    LagrangeServiceManager public lagrangeServiceManager;
    LagrangeServiceManager public lagrangeServiceManagerImp;
    
    EmptyContract public emptyContract;

    function run() public {
        string memory deployData = vm.readFile(deployDataPath);
        slasherAddress = stdJson.readAddress(
            deployData,
            ".addresses.slasher"
        );
        strategyManagerAddress = stdJson.readAddress(
            deployData,
            ".addresses.strategyManager"
        );

        vm.startBroadcast(msg.sender);

        // deploy proxy admin for ability to upgrade proxy contracts
        proxyAdmin = new ProxyAdmin();

        // deploy upgradeable proxy contracts
        emptyContract = new EmptyContract();
        lagrangeCommittee = LagrangeCommittee(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );
        lagrangeService = LagrangeService(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );
        lagrangeServiceManager = LagrangeServiceManager(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(proxyAdmin),
                    ""
                )
            )
        );

        // deploy implementation contracts
        string memory poseidonData = vm.readFile(poseidonDataPath);
        lagrangeCommitteeImp = new LagrangeCommittee(
            stdJson.readAddress(poseidonData, ".2"),
            stdJson.readAddress(poseidonData, ".3"),
            stdJson.readAddress(poseidonData, ".4"),
            lagrangeService
        );
        lagrangeServiceManagerImp = new LagrangeServiceManager(
            ISlasher(slasherAddress)
        );
        lagrangeServiceImp = new LagrangeService(
            lagrangeServiceManager,
            lagrangeCommittee,
            IStrategyManager(strategyManagerAddress)
        );

        // upgrade proxy contracts
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(address(lagrangeCommittee))), address(lagrangeCommitteeImp));
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(address(lagrangeServiceManager))), address(lagrangeServiceManagerImp));
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(address(lagrangeService))), address(lagrangeServiceImp));

        vm.stopBroadcast();

        // write deployment data to file
        string memory parent_object = "parent object";
        string memory deployed_addresses = "addresses";
        vm.serializeAddress(deployed_addresses, "proxyAdmin", address(proxyAdmin));
        vm.serializeAddress(deployed_addresses, "lagrangeCommitteeImp", address(lagrangeCommitteeImp));
        vm.serializeAddress(deployed_addresses, "lagrangeCommittee", address(lagrangeCommittee));
        vm.serializeAddress(deployed_addresses, "lagrangeServiceImp", address(lagrangeServiceImp));
        vm.serializeAddress(deployed_addresses, "lagrangeService", address(lagrangeService));
        vm.serializeAddress(deployed_addresses, "lagrangeServiceManagerImp", address(lagrangeServiceManagerImp));
        string memory deployed_output = vm.serializeAddress(deployed_addresses, "lagrangeServiceManager", address(lagrangeServiceManager));
        string memory finalJson = vm.serializeString(parent_object, deployed_addresses, deployed_output);
        vm.writeJson(finalJson, "script/output/deployed_lgr.json");
    }
}
