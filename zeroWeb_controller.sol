// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// Надо: 
// 1. Описать интерфейс в отдельном файле для моего смарта
// 2. Пофиксить второй статический массив - сделать его изменение

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
    //function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    //function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ZeroWebController is Ownable {

    struct project {
        string name;
        address projectAddress;
        uint64 tasks; 
        address tokenToPay; //token address to pay rewards
        uint256 paySum; //summ to pay for all tasks
        //string[] socialNetworks;
    }

    project[] arrayProjects; 
    mapping(address => project) public projectsAddresses;
    
    //Modifiers
    modifier onlyProject {
      require(projectsAddresses[msg.sender].projectAddress == msg.sender, "You are not registered or there is no project with this address!");
      _;
   }

    //Events
    //Replenishment of tasks and project amounts
    event FundrasingComplete(address projectAddress,  address tokenToPay, uint256 paySum, uint64 tasks);
    // Change token to pay for project
    event ChangeTokenToPay(address projectAddress, address newTokenToPay);
    // Project was added
    event AddProject(project newProject);
    // Return to project all their money
    event Refund(address projectAddress, address tokenReturned, uint256 sumReturned);
    // Project added tasks
    event AddTasks(address projectAddress, uint64 sumTasks);
    // Pay reward to user from project
    event PayReward(address to, uint256 rewardSum);

    //Functions
    function fundrasing(uint256 _paySum, uint64 _tasks, address _projectAddress) internal {
       IERC20 ERC20;

       ERC20 = IERC20(projectsAddresses[_projectAddress].tokenToPay); //take token to pay

       require(ERC20.allowance(_projectAddress, address(this)) >= _paySum, "Sum to pay is not available!");
       require(ERC20.balanceOf(_projectAddress) >= _paySum, "Project has not enough money!");

       ERC20.transferFrom(_projectAddress, address(this), _paySum);

        emit FundrasingComplete(_projectAddress, projectsAddresses[_projectAddress].tokenToPay, _paySum, _tasks);
    }

    function addProject(
        string memory _name, address _tokenToPay,
        uint256 _paySum, uint64 _tasks
        ) 
        public {
            require(
                projectsAddresses[msg.sender].projectAddress == address(0),
                "Project address is already used"
            );
            require(
                keccak256(abi.encodePacked(projectsAddresses[msg.sender].name)) == keccak256(abi.encodePacked("")),
                 "The project name has already been used!"
            ); 

            projectsAddresses[msg.sender] = project({name: _name,  projectAddress: msg.sender, tasks: _tasks, tokenToPay: _tokenToPay, paySum: _paySum});
            arrayProjects.push(projectsAddresses[msg.sender]);

            fundrasing(_paySum, _tasks, msg.sender); // Сбор средств для оплаты заданий

            emit AddProject(projectsAddresses[msg.sender]);
    }
    
    function addTasks(uint256 _paySum, uint64 _tasks) public onlyProject { 

        fundrasing(_paySum, _tasks,  msg.sender);
        
        if(projectsAddresses[msg.sender].tasks == 0) {
            projectsAddresses[msg.sender].tasks = _tasks;
        } else {
            projectsAddresses[msg.sender].tasks = projectsAddresses[msg.sender].tasks + _tasks;
        }

        if(projectsAddresses[msg.sender].paySum == 0) {
            projectsAddresses[msg.sender].paySum = _paySum;
        } else {
            projectsAddresses[msg.sender].paySum = projectsAddresses[msg.sender].paySum + _paySum;
        }

        emit AddTasks(msg.sender, _tasks);
    }

    function userPayment(address _projectAddress, address _to, uint256 _rewardSum) public onlyOwner {
        //-1 task
        //- sum
        // transfer
        IERC20 ERC20;

        ERC20 = IERC20(projectsAddresses[_projectAddress].tokenToPay);

        ERC20.transfer(_to, _rewardSum);

        projectsAddresses[_projectAddress].tasks = projectsAddresses[_projectAddress].tasks - 1;
        projectsAddresses[_projectAddress].paySum = projectsAddresses[_projectAddress].paySum - _rewardSum;

        emit PayReward(_to, _rewardSum);
    }

    function changeTokenToPay(address newToken) public onlyProject {

        IERC20 ERC20;

        if(projectsAddresses[msg.sender].paySum != 0) {
            ERC20 = IERC20(projectsAddresses[msg.sender].tokenToPay);

            emit Refund(msg.sender, projectsAddresses[msg.sender].tokenToPay, projectsAddresses[msg.sender].paySum);

            ERC20.transfer(msg.sender, projectsAddresses[msg.sender].paySum);
            projectsAddresses[msg.sender].paySum = 0;

        }

        projectsAddresses[msg.sender].tokenToPay = newToken;

        emit ChangeTokenToPay(msg.sender, projectsAddresses[msg.sender].tokenToPay);
    }

    function returnProjectByAddress(address _address) public view returns (project memory) {
        return projectsAddresses[_address];
    }

    function returnProjectsArray() public view returns (project[] memory) {
        return arrayProjects;
    }

}