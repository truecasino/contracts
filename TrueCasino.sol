// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./TrueCasinoSharesToken.sol";

contract TrueCasino {
    uint256 BASE_SHARES = uint256(10) ** 18;    
    uint256 private liquidityProviderPrcnt;
    uint256 private currentLiquidity;
    uint256 private casinoPoolLoss;
    uint256 private casinoPoolProfit;
    address private owner;
    address private acceptedToken;
    TrueCasinoSharesToken private sharesToken;

    mapping(address=>uint256) private userChipsBalance;
    mapping(address=>bool) private activeGames;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _acceptedToken, string memory _sharesName, string memory _sharesSymbol)
    {
        liquidityProviderPrcnt = 25;
        acceptedToken = _acceptedToken;
        sharesToken = new TrueCasinoSharesToken(_sharesName,_sharesSymbol);
        owner = msg.sender;
    }
    function activateGame(address _addr) public onlyOwner{
        activeGames[_addr] = true;
    }
    function removeGame(address _addr) public onlyOwner{
        activeGames[_addr] = false;
    }
    function getCasinoBalance() public view onlyOwner returns (uint256, uint256) {
        return (casinoPoolProfit,casinoPoolLoss);
    }
    function withdrawProfits() public onlyOwner{
        require(casinoPoolProfit > casinoPoolLoss,"No profit yet");
        uint256 amount = casinoPoolProfit - casinoPoolLoss;
        casinoPoolProfit = 0;
        casinoPoolLoss = 0;
        IERC20(acceptedToken).transfer(msg.sender, amount);
    }

    function getAcceptedToken() public view returns(address){
        return acceptedToken;
    }
    function getSharesToken() public view returns(address){
        return address(sharesToken);
    }
    function getSharesBalance(address _addr) public view returns(uint256){
        return IERC20(sharesToken).balanceOf(_addr);
    }
    function getSharesTotal() public view returns(uint256){
        return IERC20(sharesToken).totalSupply();
    }
    function getInvestorBalance() public view returns(uint256)
    {
        uint256 senderShares = sharesToken.balanceOf(msg.sender);
        uint256 totalShares = sharesToken.totalSupply();
        return currentLiquidity * senderShares / totalShares; 
    }
    function getCurrentLiquidity() public view returns(uint256) {
        return currentLiquidity;
    }
    function getLiquidityProviderPrcnt() public view returns (uint256) {
        return liquidityProviderPrcnt;
    }
    function removeLiquidity(uint256 _amount) public {
        uint256 senderShares = sharesToken.balanceOf(msg.sender);
        uint256 totalShares = sharesToken.totalSupply();
        require(senderShares> 0, "Your didn't provide liquidity");
        require(_amount > 0, "Can not remove ZERO amount");
        uint256 senderLiquidity = currentLiquidity * senderShares / totalShares;     
        require(_amount <= senderLiquidity, "Amount is above sender liquidity");
        uint256 sharesToBurn = _amount / senderLiquidity * senderShares;
        currentLiquidity -= _amount;
        sharesToken.burn(msg.sender, sharesToBurn);
        IERC20(acceptedToken).transfer(msg.sender, _amount);
    }

    function provideLiquidity(uint256 _amount) public {
        require(_amount > 0, "You didn't send any balance");
        require(IERC20(acceptedToken).balanceOf(msg.sender) >= _amount, "Not enough balance in your account");
        collectToken(msg.sender,_amount);
        uint256 addedLiquidity = _amount;
        uint256 currentShares = sharesToken.totalSupply();

        if (currentShares <= 0) {
            currentLiquidity += addedLiquidity;
            sharesToken.mint(msg.sender, BASE_SHARES * addedLiquidity);
            return;
        }

        uint256 new_shares = (addedLiquidity * currentShares) / (currentLiquidity);
        currentLiquidity += addedLiquidity;
        sharesToken.mint(msg.sender, new_shares);
    }

    function collectToken(address _sender, uint256 _amount) private
    {
        uint256 allowance = IERC20(acceptedToken).allowance(_sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        IERC20(acceptedToken).transferFrom(_sender, address(this), _amount);
    }


    function buyChips(address _addr, uint256 _amount) public
    {
        require(_amount > 0, "You didn't send any balance");
        require(IERC20(acceptedToken).balanceOf(_addr) >= _amount, "Not enough balance in your account");
        collectToken(_addr,_amount);
        userChipsBalance[_addr] = userChipsBalance[_addr]  + _amount;
    }
    
    function sellChips(address _addr) external
    {
        require(activeGames[msg.sender] == true, "Not Authorised");
        require(userChipsBalance[_addr] > 0, "You didn't send any balance");
        IERC20(acceptedToken).transfer(_addr, userChipsBalance[_addr]);
        userChipsBalance[_addr] = 0;
    }

    function getUserBalance(address _addr) external view returns (uint256){
        return userChipsBalance[_addr];
    }

    function makePayout(address _addr, uint256 _amount) external
    {
        require(activeGames[msg.sender] == true, "Not Authorised");
        userChipsBalance[_addr] += _amount;
        currentLiquidity -= _amount*liquidityProviderPrcnt/100;
        casinoPoolLoss += _amount*(100-liquidityProviderPrcnt)/100;
    }

    function makeDeposit(address _addr, uint256 _amount) external
    {
        require(activeGames[msg.sender] == true, "Not Authorised");
        if (userChipsBalance[_addr] < _amount)
            userChipsBalance[_addr] =0;
        else
            userChipsBalance[_addr] -=_amount;
        currentLiquidity += _amount*liquidityProviderPrcnt/100;
        casinoPoolProfit += _amount*(100-liquidityProviderPrcnt)/100;
    }
}