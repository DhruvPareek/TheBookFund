// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockERC20 {
    string public name = "Mock USDC";
    string public symbol = "mUSDC";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor() {}

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function mint(address to, uint256 amount) public {
        balances[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public view returns (uint256)
    {
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        unchecked {
            balances[msg.sender] -= amount;
        }
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        require(balances[from] >= amount, "Insufficient balance");
        unchecked {
            balances[from] -= amount;
            allowances[from][msg.sender] = currentAllowance - amount;
        }
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
