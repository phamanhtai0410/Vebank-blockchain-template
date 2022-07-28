A. Required:
====

B. Deploy:
======

    Address of factory 

1: Deploy **VeBank, VEUSD, WVET** contract

_This contract allows deploy token or load token deployed._
```
 Run: npx truffle migrate --network testnet -f 1 --to 3
```

2: Vesting VB for **PrivateSaleVBVesting** contract

_This contract will vesting token private sale;_
```
Run: npx truffle migrate --network testnet -f 4 --to 4
```

3: Vesting VB for **PublicSaleVBVesting** contract

_This contract will vesting token public sale;_
```
Run: npx truffle migrate --network testnet -f 5 --to 5
```
4: Claim VB for **VBAirdrop** contract

_This contract will vesting token airdrop;_
```
Run: npx truffle migrate --network testnet -f 6 --to 6
```
5: Deploy **VEUSDIdo** contract

_This contract will receive VEUSD from user for IDO;_
```
Run: npx truffle migrate --network testnet -f 7 --to 7
```
6: Deploy **VEUSDIdo** contract

_This contract will receive WVET from user for IDO;_
```
Run: npx truffle migrate --network testnet -f 8 --to 8
```

**Address in vechain testnet:**
=====
- VeBank: **0xc652898b0B05BBe0650aD4Ff09E37AFDf6Ec2277**
- WVET: **0xe07c5D09Cd4D8B2CFa9091c57a0cc8FE9BdB160d**
- VEUSD: **0x27BE9EA5F7300FA9a625cE238C3598abfCeB3590**
- VEUSD Ido: **0xef365Af83aae3A495A21bDCDEf88BF717f6F31C2**
- Private Sale VB Vesting: **0x66D68AE5806aD5650ac8B17fD62cAcB788CeD47f**
- Public Sale VB Vesting: **0xcf2eFBaa372b66aCD29612b269B5C54e8396a206**
- VB Airdrop: **0xfe40936975423BBd88ee2D1ce73B497785554A25**
