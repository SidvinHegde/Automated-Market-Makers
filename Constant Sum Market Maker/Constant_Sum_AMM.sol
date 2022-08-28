// Constant Sum Market Makers
// X + Y = K

pragma solidity ^0.8.13;

import "./IERC20.sol";

contract CSAMM {

    //Tokens
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    //state variables that keep track of the balance inside the contract
    uint public reserve0;
    uint public reserve1;

    //state variable total shares  
    uint public totalSupply

    //shares per user
    uint public totalSupply;
    mapping(address =>uint) public balanceOf;
    // this completes the state variables


    constructor(address _token0, address _token1){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    // internal function to mint shares to the account
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    // internal function to burn shares from the account
    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    // updating reserve after swaping
    function _update(uint _res0, uint _res1) private { 
        reserve0 = _res0;
        reserve1 = _res1;
    }

    //houses the token exchange logic.
    function swap(address _tokenIn, uint _amountIn) external returns (uint amountOut) {
        require(_tokenIn == address(token0) || _tokenIn == address(token1), "invalid token");

        bool isToken0 = _tokenIn == address(token0);
 
        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint resOut) = isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint amountIn = tokenIn.balanceOf(address(this)) - resIn;

        // 0.3% fee
        amountOut = (amountIn * 997) / 1000;

        (uint res0, uint res1) = isToken0 ? (resIn + amountIn, resOut - amountOut) : (resOut - amountOut, resIn + amountIn);

        _update(res0, res1);
        tokenOut.transfer(msg.sender, amountOut);
    }

    // function to add tokens to the AMM to add liquidity
    function addLiquidity(uint _amount0, uint _amount1) external returns (uint shares) {
        
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        uint d0 = bal0 - reserve0;
        uint d1 = bal1 - reserve;

        /* 
        a = amount in
        L = total liquidity
        s = shares to mint
        T = total supply
        
        s should be proportional to increase from L to L + a
        (L + a) / L = (T + s) / T
        
        s = a * T/L
        */

        if (totalSupply > 0)
        {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1); 
        }else{
            shares = d0 + d1;
        }

        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        _update(bal0, bal1);

    }

    // function to burn the shares and get back the tokens
    function removeLiquidity() external returns (uint d0, uint d1) {
        /*
        a = amount out
        L= total liquidity
        s = shares
        T = total supply
        
        a / L = s / T
        a = L * s / T = (reserve0 + reserve1) * s / T
        */

        d0 = (reserve0 * _shares) / totalSupply;
        d1 = (reserve1 * _shares) / totalSupply;

        _burn(msg.sender, _shares);
        _update(reserve0 - d0, reserve1 - d1);

        if (d0 > 0) {
            token0.transfer(msg.sender, d0);
        }
        if (d1 > 0) {
            token1.transfer(msg.sender, d1);
        }
    } 
}