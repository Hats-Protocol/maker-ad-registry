// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test, console2 } from "forge-std/Test.sol";
import { Hatter, DelegationContractLike } from "../src/Hatter.sol";
import { Deploy } from "../script/Hatter.s.sol";
import { IHats } from "hats-protocol/Interfaces/IHats.sol";

contract HatterTest is Deploy, Test {
  // variables inhereted from Deploy script
  // Hatter public hatter;

  uint256 public fork;
  uint256 public BLOCK_NUMBER = 17_671_864;
  IHats public HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

  string public tophatImage = "maker.png";
  uint256 public tophat;
  uint256 public registrarHat;
  uint256 public facilitatorHat;
  uint256 public delegateHat;

  address public maker = makeAddr("maker");
  address public facilitator = makeAddr("facilitator");
  address public delegate;
  uint256 public delegateKey;

  string delegateName = "Test Delegate";
  string public ecosystemActorMessage;
  bytes public ecosystemActorSignature;
  address public delegationContract1;
  address public delegationContractDelegate1;
  address public delegateEOA1;
  uint256 public delegateEOA1Key;
  string public adRecognition1;
  bytes public adRecognitionSignature1;
  address public delegationContract2;
  address public delegationContractDelegate2;
  address public delegateEOA2;
  uint256 public delegateEOA2Key;
  string public adRecognition2;
  bytes public adRecognitionSignature2;

  uint256 public expectedDelegateHatId;

  bytes public someBytes = abi.encodePacked("these are some bytes");

  HatterHarness public harness;
  SignerMock public signerContract;

  error InvalidEcosystemActorSignature();
  error InvalidADRecognitionSignature();
  error InvalidDelegationContracts();
  error InvalidContractDelegate();
  // Hats Protocol errors
  error NotAdmin(address user, uint256 hatId);

  event Registered(
    address delegate,
    string delegateName,
    uint256 delegateHatId,
    string ecosystemActorMessage,
    address delegationContract1,
    address delegationContractDelegate1,
    string aDRecognition1,
    address delegationContract2,
    address delegationContractDelegate2,
    string aDRecognition2
  );

  function setUp() public virtual {
    // create and activate a fork, at BLOCK_NUMBER
    fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

    // initiate a delegate and private key for signing
    (delegate, delegateKey) = makeAddrAndKey("delegate");
    (delegateEOA1, delegateEOA1Key) = makeAddrAndKey("delegateEOA1");
    (delegateEOA2, delegateEOA2Key) = makeAddrAndKey("delegateEOA2");

    // create a new maker hats tree, with a tophat, registrar hat, and facilitator hat
    vm.startPrank(maker);
    tophat = HATS.mintTopHat(maker, "makerDAO", tophatImage);
    registrarHat = HATS.createHat(tophat, "registrar hat", 1, maker, maker, true, "");
    facilitatorHat = HATS.createHat(registrarHat, "facilitator hat", 1, maker, maker, true, "");

    // mint the facilitator hat to the facilitator
    HATS.mintHat(facilitatorHat, facilitator);
    vm.stopPrank();

    // deploy hatter via the script; set first arg to true to log deployment addresses
    Deploy.prepare(false, registrarHat, facilitatorHat, facilitator); //
    Deploy.run();

    // mint the registar hat to the hatter
    vm.prank(maker);
    HATS.mintHat(registrarHat, address(hatter));
  }

  function signMessage(string memory message, uint256 privateKey) public pure returns (bytes memory signature) {
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes32 messageHash = keccak256(abi.encodePacked(message));
    (v, r, s) = vm.sign(privateKey, messageHash);
    signature = bytes.concat(r, s, bytes1(v));
  }
}

contract DeployTest is HatterTest {
  function test_constants() public {
    assertEq(address(hatter.HATS()), address(HATS));
    assertEq(hatter.REGISTRAR_HAT(), registrarHat);
    assertEq(hatter.FACILITATOR_HAT(), facilitatorHat);
    assertEq(hatter.FACILITATOR(), facilitator);
  }

  function test_hatterisAdminOfFacilitatorHat() public {
    assertTrue(HATS.isAdminOfHat(address(hatter), facilitatorHat));
  }
}

contract HatterHarness is Hatter {
  constructor(uint256 registrarHat, uint256 facilitatorHat, address facilitator)
    Hatter(registrarHat, facilitatorHat, facilitator)
  { }

  function isValidSignature(string calldata message, bytes calldata signature, address signer)
    public
    view
    returns (bool)
  {
    bool result = _isValidSignature(message, signature, signer);
    // console2.log("_isValidSignature() result:", result);
    return result;
  }

  function validateDelegationContractData(
    address delegationContract,
    address delegationContractDelegate,
    string calldata adRecognition,
    bytes calldata adRecognitionSig
  ) public view {
    _validateDelegationContractData(delegationContract, delegationContractDelegate, adRecognition, adRecognitionSig);
  }

  function createAndMintDelegateHat(string calldata _delegateName, address _delegate)
    public
    returns (uint256 delegateHatId)
  {
    return _createAndMintDelegateHat(_delegateName, _delegate);
  }
}

contract SignerMock {
  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

  mapping(bytes32 => bytes) public signed;

  function sign(string calldata message, bytes calldata signature) public {
    bytes32 messageHash = keccak256(abi.encodePacked(message));
    // console2.log("messageHash", messageHash);
    // console2.log("signature", signature);
    signed[messageHash] = signature;
  }

  function isValidSignature(bytes32 messageHash, bytes calldata signature) public view returns (bytes4) {
    // bytes memory sig = signature;
    if (keccak256(signed[messageHash]) == keccak256(signature)) {
      return ERC1271_MAGIC_VALUE;
    } else {
      return 0xffffffff;
    }
  }
}

contract InternalTest is HatterTest {
  function setUp() public virtual override {
    super.setUp();
    harness = new HatterHarness(registrarHat, facilitatorHat, facilitator);
  }
}

contract IsValidSignature is InternalTest {
  string message;
  bytes signature;

  function setUp() public virtual override {
    super.setUp();
    signerContract = new SignerMock();
  }

  function test_eoaSignature() public {
    message = "hello world, I am an EOA";
    signature = signMessage(message, delegateKey);

    assertTrue(harness.isValidSignature(message, signature, delegate));
  }

  function test_bad_eoaSignature_false() public {
    message = "hello world, I am a bad EOA";
    signature = someBytes;

    assertFalse(harness.isValidSignature(message, signature, maker));
  }

  function test_contractSignature() public {
    message = "hello world, I am a smart contract";
    signature = signMessage(message, delegateKey);

    vm.prank(delegate);
    signerContract.sign(message, signature);

    assertTrue(harness.isValidSignature(message, signature, address(signerContract)));
  }

  function test_bad_contractSignature_false() public {
    message = "hello world, I am a bad smart contract";
    signature = signMessage(message, delegateKey);

    vm.prank(delegate);
    signerContract.sign(message, abi.encodePacked("some other bytes"));

    assertFalse(harness.isValidSignature(message, signature, address(signerContract)));
  }
}

contract DelegationContractMock is DelegationContractLike {
  address public delegate;

  constructor(address _delegate) {
    delegate = _delegate;
  }
}

contract ValidateDelegationContractData is InternalTest {
  function setUp() public virtual override {
    super.setUp();
  }
  // happy: valid sig and delegate is correct

  function test_delegationContractMock() public {
    DelegationContractLike mock = new DelegationContractMock(delegate);

    assertEq(mock.delegate(), delegate);
    assertFalse(mock.delegate() == facilitator);
  }

  function test_happy() public {
    adRecognition1 = "I am a delegate";
    adRecognitionSignature1 = signMessage(adRecognition1, delegateEOA1Key);
    delegationContractDelegate1 = delegateEOA1;
    delegationContract1 = address(new DelegationContractMock(delegationContractDelegate1));

    harness.validateDelegationContractData(
      delegationContract1, delegationContractDelegate1, adRecognition1, adRecognitionSignature1
    );
  }

  // invalid sig and valid delegate
  function test_revert_invalidSig() public {
    adRecognition1 = "I am a delegate";
    adRecognitionSignature1 = someBytes; // invalid sig
    delegationContractDelegate1 = delegateEOA1;
    delegationContract1 = address(new DelegationContractMock(delegationContractDelegate1));

    vm.expectRevert(InvalidADRecognitionSignature.selector);

    harness.validateDelegationContractData(
      delegationContract1, delegationContractDelegate1, adRecognition1, adRecognitionSignature1
    );
  }

  // valid sig and invalid delegate
  function test_revert_invalidDelegate() public {
    adRecognition1 = "I am a delegate";
    adRecognitionSignature1 = signMessage(adRecognition1, delegateEOA1Key);
    delegationContractDelegate1 = delegateEOA1;
    delegationContract1 = address(new DelegationContractMock(address(999))); // invalid delegate

    vm.expectRevert(InvalidContractDelegate.selector);

    harness.validateDelegationContractData(
      delegationContract1, delegationContractDelegate1, adRecognition1, adRecognitionSignature1
    );
  }
}

contract CreateAndMintDelegateHat is InternalTest {
  string details;
  uint32 maxSupply;
  uint32 supply;
  address eligibility;
  address toggle;
  string imageURI;
  uint16 lastHatId;
  bool mutable_;
  bool active;

  function expectedDetails(string memory _delegateName) public view returns (string memory) {
    return string(abi.encodePacked("Aligned Delegate: ", _delegateName));
  }

  function test_createAndMintSucceeds() public {
    // give the harness the registrar hat
    vm.prank(maker);
    HATS.transferHat(registrarHat, address(hatter), address(harness));

    delegateHat = harness.createAndMintDelegateHat(delegateName, delegate);

    (details, maxSupply, supply, eligibility, toggle, imageURI, lastHatId, mutable_, active) = HATS.viewHat(delegateHat);

    assertTrue(HATS.isAdminOfHat(address(harness), delegateHat));
    assertTrue(HATS.isAdminOfHat(facilitator, delegateHat));
    assertEq(details, expectedDetails(delegateName));
    assertEq(eligibility, facilitator);
    assertEq(toggle, facilitator);
    assertTrue(mutable_);
    assertEq(imageURI, tophatImage);
    assertEq(maxSupply, 1);
    assertTrue(HATS.isWearerOfHat(delegate, delegateHat));
  }

  function test_revert_notRegistrarHatWearer() public {
    // harness is not registrar hat wearer
    assertFalse(HATS.isWearerOfHat(address(harness), registrarHat));

    expectedDelegateHatId = HATS.getNextId(facilitatorHat);

    vm.expectRevert(abi.encodeWithSelector(NotAdmin.selector, harness, expectedDelegateHatId));
    harness.createAndMintDelegateHat(delegateName, delegate);
  }
}
}
