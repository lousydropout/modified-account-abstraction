// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// deployed on Ethereum Sepolia testnet
// contract address: 0x51EAE7C1ac83fC8acA9412c0F698c5d4F874346b

import {IRouterClient} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from
    "@chainlink/contracts-ccip@1.4.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@chainlink/contracts-ccip@1.4.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

/// @title - A "Configuration" contract for receiving data about how many transactions to allot per contract per user.
contract Configuration is CCIPReceiver, OwnerIsCreator {
    // e.g. remainingTxs[contractAddress][userAddress] = 500
    mapping(address => mapping(address => uint256)) public remainingTxs;

    // e.g. userAccounts[contractAddress][username] = 0x16E4************1063Ba
    mapping(address => mapping(string => address)) public userAccounts;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event UserAdded(string username, address indexed contractAddress, address indexed userAccount);

    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.
    error SourceChainNotAllowlisted(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowlisted(address sender); // Used when the sender has not been allowlisted by the contract owner.

    string private s_lastReceivedText; // Store the last received text.
    address public s_lastReceivedTextAsAddress;

    // Mapping to keep track of allowlisted destination chains.
    mapping(uint64 => bool) public allowlistedDestinationChains;

    // Mapping to keep track of allowlisted source chains.
    mapping(uint64 => bool) public allowlistedSourceChains;

    // Mapping to keep track of allowlisted senders.
    mapping(address => bool) public allowlistedSenders;

    // Emitted when an acknowledgment message is successfully sent back to the sender contract.
    // This event signifies that the Acknowledger contract has recognized the receipt of an initial message
    // and has informed the original sender contract by sending an acknowledgment message,
    // including the original message ID.
    // The chain selector of the destination chain.
    // The address of the receiver on the destination chain.
    // The data being sent back, containing the message ID of the initial message to acknowledge.
    // The token address used to pay CCIP fees for sending the acknowledgment.
    // The fees paid for sending the acknowledgment message via CCIP.
    event AcknowledgmentSent( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        bytes32 data,
        address feeToken,
        uint256 fees
    );

    IERC20 private s_linkToken;

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    constructor(address _router, address _link) CCIPReceiver(_router) {
        s_linkToken = IERC20(_link);
    }

    /// @dev Modifier that checks if the chain with the given destinationChainSelector is allowlisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector]) {
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        }
        _;
    }

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    /// @param _sender The address of the sender.
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector]) {
            revert SourceChainNotAllowlisted(_sourceChainSelector);
        }
        if (!allowlistedSenders[_sender]) revert SenderNotAllowlisted(_sender);
        _;
    }

    /// @dev Updates the allowlist status of a destination chain for transactions.
    function allowlistDestinationChain(uint64 _destinationChainSelector, bool allowed) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a source chain for transactions.
    function allowlistSourceChain(uint64 _sourceChainSelector, bool allowed) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a sender for transactions.
    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    //////////////////////////////////////////////////////////////////////
    // non-message-receiver-related functions
    /// increment remaining transactions for a user by specified value
    function incrementBy(address _userAddress, address _contractAddress, uint256 _value) public onlyOwner {
        remainingTxs[_contractAddress][_userAddress] += _value;
    }

    /// decrement remaining transactions for a user by 1
    function decrement(address _userAddress, address _contractAddress) public onlyOwner returns (bool) {
        if (remainingTxs[_contractAddress][_userAddress] == 0) {
            return false;
        }

        // all arithmetic calculations are checked for underflow in Solidity 0.8.0 and later
        remainingTxs[_contractAddress][_userAddress]--;
        return true;
    }

    // Getters

    function getRemainingTxs(address _userAddress, address _contractAddress) public view returns (uint256) {
        return remainingTxs[_contractAddress][_userAddress];
    }

    function getUserAccount(string memory _username, address _contractAddress) public view returns (address) {
        return userAccounts[_contractAddress][_username];
    }

    //////////////////////////////////////////////////////////////////////

    /// @notice Sends an acknowledgment message back to the sender contract on the source chain
    /// and pays the fees using LINK tokens.
    /// @dev This function constructs and sends an acknowledgment message using CCIP,
    /// indicating the receipt and processing of an initial message. It emits the `AcknowledgmentSent` event
    /// upon successful sending. This function should be called after processing the received message
    /// to inform the sender contract about the successful message reception.
    /// @param _messageIdToAcknowledge The message ID of the initial message being acknowledged.
    /// @param _messageTrackerAddress The address of the message tracker contract on the source chain.
    /// @param _messageTrackerChainSelector The chain selector of the source chain.
    function _acknowledgePayLINK(
        bytes32 _messageIdToAcknowledge,
        address _messageTrackerAddress,
        uint64 _messageTrackerChainSelector
    ) private {
        if (_messageTrackerAddress == address(0)) {
            revert InvalidReceiverAddress();
        }

        // Construct the CCIP message for acknowledgment, including the message ID of the initial message.
        Client.EVM2AnyMessage memory acknowledgment = Client.EVM2AnyMessage({
            receiver: abi.encode(_messageTrackerAddress), // ABI-encoded receiver address
            data: abi.encode(_messageIdToAcknowledge), // ABI-encoded message ID to acknowledge
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: address(s_linkToken)
        });

        // Initialize a router client instance to interact with the cross-chain router.
        IRouterClient router = IRouterClient(this.getRouter());

        // Calculate the fee required to send the CCIP acknowledgment message.
        uint256 fees = router.getFee(
            _messageTrackerChainSelector, // The chain selector for routing the message.
            acknowledgment // The acknowledgment message data.
        );

        // Ensure the contract has sufficient balance to cover the message sending fees.
        if (fees > s_linkToken.balanceOf(address(this))) {
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);
        }

        // Approve the router to transfer LINK tokens on behalf of this contract to cover the sending fees.
        s_linkToken.approve(address(router), fees);

        // Send the acknowledgment message via the CCIP router and capture the resulting message ID.
        bytes32 messageId = router.ccipSend(
            _messageTrackerChainSelector, // The destination chain selector.
            acknowledgment // The CCIP message payload for acknowledgment.
        );

        // Emit an event detailing the acknowledgment message sending, for external tracking and verification.
        emit AcknowledgmentSent(
            messageId, // The ID of the sent acknowledgment message.
            _messageTrackerChainSelector, // The destination chain selector.
            _messageTrackerAddress, // The receiver of the acknowledgment, typically the original sender.
            _messageIdToAcknowledge, // The original message ID that was acknowledged.
            address(s_linkToken), // The fee token used.
            fees // The fees paid for sending the message.
        );
    }

    // helper function: taken from @BonisTech's response on StackExchange:
    // <https://ethereum.stackexchange.com/questions/10932/how-to-convert-string-to-int/18035#18035>
    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    // helper function: taken from @Dakata's response on StackExchange:
    // <https://ethereum.stackexchange.com/questions/43463/how-to-convert-string-to-address>
    function stringToAddress(string memory _address) public pure returns (address) {
        string memory cleanAddress = remove0xPrefix(_address);
        bytes20 _addressBytes = parseHexStringToBytes20(cleanAddress);
        return address(_addressBytes);
    }

    function remove0xPrefix(string memory _hexString) internal pure returns (string memory) {
        if (
            bytes(_hexString).length >= 2 && bytes(_hexString)[0] == "0"
                && (bytes(_hexString)[1] == "x" || bytes(_hexString)[1] == "X")
        ) {
            return substring(_hexString, 2, bytes(_hexString).length);
        }
        return _hexString;
    }

    function substring(string memory _str, uint256 _start, uint256 _end) internal pure returns (string memory) {
        bytes memory _strBytes = bytes(_str);
        bytes memory _result = new bytes(_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _result[i - _start] = _strBytes[i];
        }
        return string(_result);
    }

    function parseHexStringToBytes20(string memory _hexString) internal pure returns (bytes20) {
        bytes memory _bytesString = bytes(_hexString);
        uint160 _parsedBytes = 0;
        for (uint256 i = 0; i < _bytesString.length; i += 2) {
            _parsedBytes *= 256;
            uint8 _byteValue = parseByteToUint8(_bytesString[i]);
            _byteValue *= 16;
            _byteValue += parseByteToUint8(_bytesString[i + 1]);
            _parsedBytes += _byteValue;
        }
        return bytes20(_parsedBytes);
    }

    function parseByteToUint8(bytes1 _byte) internal pure returns (uint8) {
        if (uint8(_byte) >= 48 && uint8(_byte) <= 57) {
            return uint8(_byte) - 48;
        } else if (uint8(_byte) >= 65 && uint8(_byte) <= 70) {
            return uint8(_byte) - 55;
        } else if (uint8(_byte) >= 97 && uint8(_byte) <= 102) {
            return uint8(_byte) - 87;
        } else {
            revert(string(abi.encodePacked("Invalid byte value: ", _byte)));
        }
    }

    function slice(string memory _str, uint256 _start) public pure returns (string memory) {
        return substring(_str, _start, bytes(_str).length);
    }

    /// @dev Handles a received CCIP message, processes it, and acknowledges its receipt.
    /// This internal function is called upon the receipt of a new message via CCIP from an allowlisted source chain and sender.
    /// It decodes the message and acknowledges its receipt by calling `_acknowledgePayLINK`.
    /// @param any2EvmMessage The CCIP message received
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowlisted(any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address))) // Make sure source chain and sender are allowlisted
    {
        bytes32 messageIdToAcknowledge = any2EvmMessage.messageId; // The message ID of the received message to acknowledge
        address messageTrackerAddress = abi.decode(any2EvmMessage.sender, (address)); // ABI-decoding of the message tracker address
        uint64 messageTrackerChainSelector = any2EvmMessage.sourceChainSelector; // The chain selector of the received message
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text

        // convert and store text as address
        // expected data format: <address><address><uint256>
        require(bytes(s_lastReceivedText).length > 84);
        address _contractAddress = stringToAddress(substring(s_lastReceivedText, 0, 42));
        address _userAddress = stringToAddress(substring(s_lastReceivedText, 42, 84));
        uint256 _txs = stringToUint(slice(s_lastReceivedText, 84));

        incrementBy(_userAddress, _contractAddress, _txs);

        _acknowledgePayLINK(messageIdToAcknowledge, messageTrackerAddress, messageTrackerChainSelector);
    }

    /// @notice Fetches the details of the last received message.
    /// @return text The last received text.
    function getLastReceivedMessage() external view returns (string memory text) {
        return (s_lastReceivedText);
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token.
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param _beneficiary The address to which the tokens will be sent.
    /// @param _token The contract address of the ERC20 token to be withdrawn.
    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).safeTransfer(_beneficiary, amount);
    }
}
