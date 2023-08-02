// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";

interface DelegationContractLike {
  function delegate() external view returns (address);
  function chief() external view returns (address);
  function expiration() external view returns (uint256);
  function gov() external view returns (address);
  function iou() external view returns (address);
  function polling() external view returns (address);
  function stake(address staker) external view returns (uint256);
}

contract Hatter {
  /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
  //////////////////////////////////////////////////////////////*/

  error InvalidEcosystemActorSignature();
  error InvalidADRecognitionSignature();
  error InvalidContractDelegate();
  error InvalidContractChief();
  error InvalidContractExpiration();
  error InvalidContractGov();
  error InvalidContractIOU();
  error InvalidContractPolling();

  /*//////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  event Registered(
    string delegateName,
    string ecosystemActorMessage,
    address delegationContract1,
    address delegationContractDelegate1,
    string aDRecognition1,
    address delegationContract2,
    address delegationContractDelegate2,
    string aDRecognition2
  );

  /*//////////////////////////////////////////////////////////////
                              CONSTANTS
  //////////////////////////////////////////////////////////////*/

  // Hats protocol contract address: v1.hatsprotocol.eth
  IHats constant HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

  // Aligned Delegate Registrar hat: the hat that this contract will wear
  uint256 immutable REGISTRAR_HAT;

  // AD Facilitator hat: the admin of the delegate hats this contract will create
  uint256 immutable FACILITATOR_HAT;

  // Facilitator address
  address immutable FACILITATOR;

  // Delegation contract data to validate
  address immutable CHIEF;
  address immutable EXPIRATION;
  address immutable GOV;
  address immutable IOU;
  address immutable POLLING;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(
    uint256 registrarHat,
    uint256 facilitatorHat,
    address facilitator,
    address chief,
    address expiration,
    address gov,
    address iou,
    address polling
  ) {
    REGISTRAR_HAT = registrarHat;
    FACILITATOR_HAT = facilitatorHat;
    FACILITATOR = facilitator;
    CHIEF = chief;
    EXPIRATION = expiration;
    GOV = gov;
    IOU = iou;
    POLLING = polling;
  }

  /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  // TODO consider using arrays to reduce likelihood of stack too deep errors
  function register(
    string calldata delegateName,
    string calldata ecosystemActorMessage,
    bytes calldata ecosystemActorSig,
    address delegationContract1,
    address delegationContractDelegate1,
    string calldata adRecognition1,
    bytes calldata adRecognitionSig1,
    address delegationContract2,
    address delegationContractDelegate2,
    string calldata adRecognition2,
    bytes calldata adRecognitionSig2
  ) external returns (uint256 delegateHatId) {
    // 1. validate ecosystemActorSig signer: signer should match msg.sender, and revert if invalid
    if (!_isValidSignature(ecosystemActorMessage, ecosystemActorSig, msg.sender)) {
      revert InvalidEcosystemActorSignature();
    }

    // 2. validate data for each delegation contract, and revert if invalid
    _validateDelegationContractData(delegationContract1, delegationContractDelegate1, adRecognition1, adRecognitionSig1);

    _validateDelegationContractData(delegationContract2, delegationContractDelegate2, adRecognition2, adRecognitionSig2);

    // 3. create new delegate hat
    delegateHatId = HATS.createHat(
      FACILITATOR_HAT, // admin
      string.concat("Aligned Delegate: ", delegateName), // details
      1, // max supply
      FACILITATOR, // eligibility
      FACILITATOR, // toggle
      true, // mutable
      "" // image; will be inherited from parent hat if empty
    );

    // 4. mint delegate hat to msg.sender
    HATS.mintHat(delegateHatId, msg.sender);

    // 5. emit Registered event
    emit Registered(
      delegateName,
      ecosystemActorMessage,
      delegationContract1,
      delegationContractDelegate1,
      adRecognition1,
      delegationContract2,
      delegationContractDelegate2,
      adRecognition2
    );
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function _validateDelegationContractData(
    address delegationContract,
    address delegationContractDelegate,
    string calldata adRecognition,
    bytes calldata adRecognitionSig
  ) internal view {
    // a. adRecognitionSig must be a valid signature of adRecognition by delegationContractDelegate
    if (!_isValidSignature(adRecognition, adRecognitionSig, delegationContractDelegate)) {
      revert InvalidADRecognitionSignature();
    }

    DelegationContractLike dc = DelegationContractLike(delegationContract);

    // b. delegationContractDelegate must be the delegate of delegationContract
    if (delegationContractDelegate != dc.delegate()) {
      revert InvalidContractDelegate();
    }

    // c. validate other properties of delegationContract, and revert if invalid
    // QUESTION are these necessary?
    if (dc.chief() != CHIEF) revert InvalidContractChief();
    if (dc.gov() != GOV) revert InvalidContractGov();
    if (dc.iou() != IOU) revert InvalidContractIOU();
    if (dc.polling() != POLLING) revert InvalidContractPolling();

    // QUESTION is this the right check?
    if (dc.expiration() < block.timestamp) revert InvalidContractExpiration();

    // QUESTION do we need to validate stake?
  }

  function _isValidSignature(string calldata message, bytes calldata signature, address signer)
    internal
    view
    returns (bool)
  {
    // encode the message as bytes and hash it
    bytes32 messageHash = keccak256(abi.encodePacked(message));

    // check signature validity using recover for EOA and ERC1271 for contract
    return SignatureCheckerLib.isValidSignatureNowCalldata(signer, messageHash, signature);
  }
}
