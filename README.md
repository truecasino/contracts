# Smart Contracts

Contracts description:

1. **TrueCasino.sol**

This is a main casino contract. Functionalities: 
- providing/removing balance from casino reserve by liquidity providers
- exchange of stable coins for CHIPs by players
- payout distribution of player's bets
- adding/removing casino hames 

2. **TrueRoulette.sol**

This is a contract of our flagship product - European Roulette. Functionalities:
- managing players bets
- payout calculation of player's bets

3. **TrueCasinoSharesToken.sol**

This is a SharesToken for liquidity providers. Currently, everybody can provide liquidity for 25% shares profit of casino revenue. The rest 75% is distributed to casino owners.

4. **TestUSDCToken.sol**

Currenly, True casino operates on Polygon mainnet, but uses Test USDC ERC-20 token for payments. The user can mint 100 Test USDC tokens in the Wallet dialog one connected.

All contracts are deployed on Polygon mainnet. Deployment addresses:

TrueCasino.sol: 0xd0e6Ee39652A658Ca5760044ea6D8B69411ac6EB

TrueRoulette.sol: 0x3489e81704F9f8289EfD28433E96698fF645e677

TestUSDCToken.sol: 0x40A058A37787Fc7F5427c1Ad79541Aa9254C6e27
