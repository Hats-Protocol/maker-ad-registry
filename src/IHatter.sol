// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHatter {
  /*//////////////////////////////////////////////////////////////
                              CONSTANTS
  //////////////////////////////////////////////////////////////*/

  // Hats protocol contract address: v1.hatsprotocol.eth
  function HATS() external view returns (address);

  // Aligned Delegate Registrar hat: the hat that this contract will wear
  function REGISTRAR_HAT() external view returns (uint256);

  // AD Facilitator hat: the admin of the delegate hats this contract will create
  function FACILITATOR_HAT() external view returns (uint256);

  // Facilitator address
  function FACILITATOR() external view returns (address);

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
  ) external returns (uint256 delegateHatId);
}
