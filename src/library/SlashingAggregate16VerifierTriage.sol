// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {ISlashingAggregate16VerifierTriage} from "../interfaces/ISlashingAggregate16VerifierTriage.sol";
import {Verifier} from "./slashing_aggregate_16/verifier.sol";

contract SlashingAggregate16VerifierTriage is
    ISlashingAggregate16VerifierTriage,
    Initializable,
    OwnableUpgradeable
{
    
    mapping(uint256 => address) public verifiers;

    constructor() {}

    function initialize(
      address initialOwner
    ) external initializer {
        _transferOwnership(initialOwner);
    }

    struct proofParams {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[5] input;
    }
    
    function setRoute(uint256 routeIndex, address verifierAddress) external onlyOwner {
        verifiers[routeIndex] = verifierAddress;
    }

    function verify(bytes calldata proof, uint256 committeeSize) external override returns (bool,uint[5] memory) {
        uint256 routeIndex = _computeRouteIndex(committeeSize);
        address verifierAddress = verifiers[routeIndex];
       
        require(verifierAddress != address(0), "SlashingSingleVerifierTriage: Verifier address not set for committee size specified.");
        
        Verifier verifier = Verifier(verifierAddress);
        proofParams memory params = abi.decode(proof,(proofParams));
        bool result = verifier.verifyProof(params.a, params.b, params.c, params.input);
        
        return (result,params.input);
    }
    
    function _computeRouteIndex(uint256 committeeSize) internal pure returns (uint256) {
        uint256 routeIndex = 1;
        while (routeIndex < committeeSize) {
            routeIndex = routeIndex * 2;
        }
        return routeIndex;
    }
}

