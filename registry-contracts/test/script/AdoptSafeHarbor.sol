// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @notice Importing these packages directly due to naming conflicts between "Account" and "Chain" structs.
import {TestBase} from "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import "../../src/v1/SafeHarborRegistry.sol";
import "../../script/v1/AdoptSafeHarborV1.s.sol";
import "../../script/v1/DeployRegistryV1.s.sol";
import {getMockAgreementDetails, logAgreementDetails} from "../v1/mock.sol";

contract AdoptSafeHarborV1Test is TestBase, DSTest {
    uint256 mockKey;
    address mockAddress;
    SafeHarborRegistry registry;
    string json;

    function setUp() public {
        // Deploy the safeharborRegistry
        string memory fakePrivateKey = "0xf0931a501a9b5fd5183d01f35526e5bc64d05d9d25d4005a8b1600ed6cd8d795";
        vm.setEnv("REGISTRY_DEPLOYER_PRIVATE_KEY", fakePrivateKey);

        DeployRegistryV1 script = new DeployRegistryV1();
        script.run();

        address fallbackRegistry = address(0);
        address registryAddr = script.getExpectedAddress(fallbackRegistry);

        mockKey = 0xA11;
        mockAddress = vm.addr(mockKey);
        registry = SafeHarborRegistry(registryAddr);
        json = vm.readFile("test/v1/mock.json");
    }

    function test_run() public {
        AdoptSafeHarborV1 script = new AdoptSafeHarborV1();
        script.adopt(mockKey, registry, json);

        // Check if the agreement was adopted
        address agreementAddr = registry.getAgreement(mockAddress);
        AgreementV1 agreement = AgreementV1(agreementAddr);
        AgreementDetailsV1 memory gotDetails = agreement.getDetails();

        console.logString("--------------------------GOT--------------------------");
        logAgreementDetails(gotDetails);
        console.logString("--------------------------WANT--------------------------");
        logAgreementDetails(getMockAgreementDetails(address(0x1111111111111111111111111111111111111111)));

        assertEq(
            registry.hash(getMockAgreementDetails(address(0x1111111111111111111111111111111111111111))),
            registry.hash(gotDetails)
        );
    }
}
