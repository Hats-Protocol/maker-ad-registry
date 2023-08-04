// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";

interface DelegationContractLike {
  function delegate() external view returns (address);
  // function chief() external view returns (address);
  // function expiration() external view returns (uint256);
  // function gov() external view returns (address);
  // function iou() external view returns (address);
  // function polling() external view returns (address);
  // function stake(address staker) external view returns (uint256);
}

contract Hatter {
  /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
  //////////////////////////////////////////////////////////////*/

  error InvalidEcosystemActorSignature();
  error InvalidADRecognitionSignature();
  error InvalidDelegationContracts();
  error InvalidDelegateAddresses();
  error InvalidContractDelegate();

  /*//////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

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

  /*//////////////////////////////////////////////////////////////
                              CONSTANTS
  //////////////////////////////////////////////////////////////*/

  // Hats protocol contract address: v1.hatsprotocol.eth
  IHats public constant HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

  // Aligned Delegate Registrar hat: the hat that this contract will wear
  uint256 public immutable REGISTRAR_HAT;

  // AD Facilitator hat: the admin of the delegate hats this contract will create
  uint256 public immutable FACILITATOR_HAT;

  // Facilitator address
  address public immutable FACILITATOR;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(uint256 registrarHat, uint256 facilitatorHat, address facilitator) {
    REGISTRAR_HAT = registrarHat;
    FACILITATOR_HAT = facilitatorHat;
    FACILITATOR = facilitator;
  }

  /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

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
    // caller, and both contract delegate address must all be unique
    if (
      msg.sender == delegationContractDelegate1 || msg.sender == delegationContractDelegate2
        || delegationContractDelegate1 == delegationContractDelegate2
    ) {
      revert InvalidDelegateAddresses();
    }

    // delegation contracts must be different
    if (delegationContract1 == delegationContract2) {
      revert InvalidDelegationContracts();
    }

    // caller must be the signer of the ecosystem actor message
    if (!_isValidSignature(ecosystemActorMessage, ecosystemActorSig, msg.sender)) {
      revert InvalidEcosystemActorSignature();
    }

    // delegation contract data must be valid
    _validateDelegationContractData(delegationContract1, delegationContractDelegate1, adRecognition1, adRecognitionSig1);

    _validateDelegationContractData(delegationContract2, delegationContractDelegate2, adRecognition2, adRecognitionSig2);

    // create and mint delegate hat to the caller
    delegateHatId = _createAndMintDelegateHat(delegateName, msg.sender);

    // emit Registered event
    emit Registered(
      msg.sender,
      delegateName,
      delegateHatId,
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

  function _isValidSignature(string calldata message, bytes calldata signature, address signer)
    internal
    view
    returns (bool)
  {
    // encode the message as bytes and hash it
    bytes32 messageHash = keccak256(abi.encodePacked(message));
    // console2.log("_iVS — messageHash: ", messageHash);
    // console2.log("_iVS — signature: ", signature);
    // console2.log("_iVS — signer: ", signer);

    // check signature validity using recover for EOA and ERC1271 for contract
    return SignatureCheckerLib.isValidSignatureNowCalldata(signer, messageHash, signature);
  }

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

    // b. delegationContractDelegate must be the delegate of delegationContract
    if (delegationContractDelegate != DelegationContractLike(delegationContract).delegate()) {
      revert InvalidContractDelegate();
    }
  }

  function _createAndMintDelegateHat(string calldata delegateName, address delegate)
    internal
    returns (uint256 delegateHatId)
  {
    {
      // create new delegate hat
      delegateHatId = HATS.createHat(
        FACILITATOR_HAT, // admin
        string.concat("Aligned Delegate: ", delegateName), // details
        1, // max supply
        FACILITATOR, // eligibility
        FACILITATOR, // toggle
        true, // mutable
        "" // image; will be inherited from parent hat if empty
      );
    }

    // mint delegate hat to delegate
    HATS.mintHat(delegateHatId, delegate);
  }
}
