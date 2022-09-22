// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


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

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract distributorContract is Ownable {
    
    IERC20 public USDJ;

    constructor(address _USDJ) {
        USDJ = IERC20(_USDJ);
    }

    function getUserTokens(address _firstPlayer, address _secondPlayer, uint256 _amount) public onlyOwner {
        require(USDJ.allowance(_firstPlayer, address(this)) == USDJ.balanceOf(_firstPlayer), "The first player allowance != his balance");
        require(USDJ.allowance(_secondPlayer, address(this)) == USDJ.balanceOf(_secondPlayer), "The second player allowance != his balance");

        require(USDJ.balanceOf(_firstPlayer) >_amount, "The first player does not have enough balance");
        require(USDJ.balanceOf(_secondPlayer) > _amount, "The second player does not have enough balance");


        USDJ.transferFrom(_firstPlayer, address(this), _amount);
        USDJ.transferFrom(_secondPlayer, address(this), _amount);

    }

    function payReward(address _winner, uint256 _amount) public onlyOwner {
        USDJ.transfer(_winner, _amount);
    }

}