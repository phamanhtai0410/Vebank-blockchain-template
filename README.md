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
- VeBank: **0x382C702c24Cf61e7A76e3996C3249Fe63462D9e1**
- WVET: **0xE4175E3E50b7A5909cC982e2a6Be2603388cfe9e**
- VEUSD: **0x0983413f99b8e9539A4D2FbCbd102ce34E60c4d5**
- VEUSD Ido: **0xFb10AFd283489843fC88bfAA4de6B026660f346e**
- Private Sale VB Vesting: **0x1e2b3AfC78163db55E6FEB6e5881c085086940EC**
- Public Sale VB Vesting: **0xf6dDA4affD2C7627Ea34eA7c32904c249AB150B8**
- VB Airdrop: **0xE899287A2a9ed7459A9121517F8e4CC413901c0d**
