pragma solidity 0.8.3;
pragma abicoder v2;
// This MultiSig Wallet can start with 2 owners and can add after deployed up to 10 max owners


contract MultiSigWallet{
    
    event Deposit(address indexed _from, uint amount, uint balance);
    event proposedTransactions (address _from, address _to, uint amount, uint _txId);
    event signedTransactions (uint _txId, uint _signatures, address _signedBy);
    event confirmedTransactions (uint _txId);
    
    address[] public owners;
    uint public sigRequired;


    struct Transaction {
        address payable to;
        uint amount;
        uint txId;
        bool confirmed;
        uint sigNumber;
    }
    mapping(address => bool) isOwner;
    mapping(address => uint) public balance;
    mapping(uint => mapping(address => bool)) isSigned;

    Transaction[] transactions;

    modifier onlyOwners() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor(address[] memory _owners, uint _sigRequired) {
        require(_sigRequired <= _owners.length && _sigRequired > 0 && _sigRequired > (_owners.length / 2), "Number of required signatures must be more than half of Owners"); 
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        sigRequired = _sigRequired;
    }

    function deposit() public payable {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    function getWalletBalance() public view returns(uint) {
        return balance[msg.sender];
    }

    function proposeTransaction(uint _amount, address payable _to) public onlyOwners {
        emit proposedTransactions(msg.sender, _to, _amount, transactions.length);
        transactions.push(Transaction(_to, _amount, transactions.length, false, 0));
    }
  
    function signTransaction(uint _txId) public onlyOwners {
        require(isSigned[_txId][msg.sender] == false); 
        Transaction storage transaction = transactions[_txId];
        transaction.sigNumber ++;
        isSigned[_txId][msg.sender] = true;
        
        emit signedTransactions(_txId, transactions[_txId].sigNumber, msg.sender);
    }
    
    function executeTransaction(uint _txId) public onlyOwners{
        require(transactions[_txId].confirmed == false);     
        if(transactions[_txId].sigNumber >= sigRequired){
            transactions[_txId].confirmed = true;
            transactions[_txId].to.transfer(transactions[_txId].amount);
            emit confirmedTransactions(_txId);
        }
    }
    
    function getTransaction() public view returns(Transaction[] memory){
        return transactions;
    }
    
    function addOwner(address _newOwner) public {
        require(_newOwner != address(0), "invalid owner");
        require(!isOwner[_newOwner], "owner not unique");
        require(owners.length < 10, "Owner slot full"); // count starts with 0

        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        sigRequired++; // adds 1 to the number of signature required per new owner

    }
}
