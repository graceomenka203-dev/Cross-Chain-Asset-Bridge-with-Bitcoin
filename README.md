# Cross-Chain Asset Bridge with Bitcoin

A minimal Clarity smart contract that mints a wrapped BTC fungible token on Stacks when a Bitcoin deposit is attested, and burns tokens to request a BTC withdrawal handled off-chain by the bridge operator.

## Features

- WBTC token: mint, burn, transfer
- Admin attestation for BTC deposits -> user claims WBTC
- User-initiated burn to request BTC withdrawal
- Admin marks withdrawals as processed
- Pause/resume bridge operations

## Files

- contracts/Cross-Chain-Asset-Bridge-with-Bitcoin.clar

## Quick start

- Ensure Clarinet is installed
- From the project root:

```bash
clarinet check
```

If you see warnings but no errors, the contract compiled successfully.

## Normalize line endings (Windows PowerShell)

```powershell
(Get-Content "contracts/Cross-Chain-Asset-Bridge-with-Bitcoin.clar" -Raw).Replace("`r`n", "`n") | Set-Content "contracts/Cross-Chain-Asset-Bridge-with-Bitcoin.clar" -NoNewline
```

## Initialize

After deployment, set the owner once:

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin bootstrap 'SPXXXX...)
```

## Admin: attest a BTC deposit → user claim

1) Admin attests a BTC txid, recipient, amount (in token base units):

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin attest-btc-deposit 0x<32-bytes-txid> 'SPRECIPIENT... u1000)
```

2) Recipient claims WBTC:

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin claim 0x<32-bytes-txid>)
```

## Users: transfer and balance

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin transfer u100 'SPOTHER...)
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin get-wbtc-balance 'SPME...)
```

## Users: request BTC withdrawal (burn)

Provide BTC address bytes (up to 64) and amount:

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin request-withdraw u500 0x<btc-address-as-buff>)
```

The call returns a request id starting at u1.

## Admin: mark withdrawal processed

Optionally include the BTC txid:

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin mark-withdraw-processed u1 (some 0x<32-bytes-txid>))
```

## Pause / resume

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin set-paused true)
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin set-paused false)
```

## Read-only helpers

```clarity
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin get-owner)
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin get-claim 0x<txid>)
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin get-withdraw u1)
(contract-call? .Cross-Chain-Asset-Bridge-with-Bitcoin token-total-supply)
```

## Development with Clarinet

```bash
clarinet console
```

Inside the console you can invoke the functions shown above. Use principals for your test wallets and provide buffers for txids/addresses.

## Notes

- Uses stacks-block-height for on-chain timestamps.
- Admin is set via bootstrap once.

## 🧪 Testing

- Add tests under tests/ and run:

```bash
npm install
npm test
```
