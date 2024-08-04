{ lib, coreutils, writeScriptBin, cardano-hw-cli, cardano-cli, cardano-address, gnutar, gzip, jq }:
let
  packages = [ cardano-hw-cli cardano-cli coreutils gnutar gzip cardano-address jq ];
  scriptHeader = ''
    PATH=${lib.makeBinPath packages}
    set -euo pipefail
    NET_ARGS=("--mainnet")
    START=-1
    END=-1
    WALLET=""
    UTXO=0
    TTL=0
    POOLS=0
    FEE=180000
    function extract_keys() {
      ACCOUNT="$1"
      WALLET="$2"
      if [ ! -f "$WALLET" ]
      then
        cardano-hw-cli shelley address key-gen --path "1852H/1815H/''${ACCOUNT}H/2/0" --hw-signing-file "stake''${ACCOUNT}.hwsfile" --verification-key-file "stake''${ACCOUNT}.vkey"
        cardano-hw-cli shelley address key-gen --path "1852H/1815H/''${ACCOUNT}H/0/0" --hw-signing-file "payment''${ACCOUNT}-0.hwsfile" --verification-key-file "payment''${ACCOUNT}-0.vkey"
      else
        cardano-address key child "1852H/1815H/''${ACCOUNT}H/0/0" < "$WALLET" | cardano-cli shelley key convert-cardano-address-key --shelley-payment-key --signing-key-file /dev/stdin --out-file "payment''${ACCOUNT}-0.skey"
        cardano-cli shelley key verification-key --signing-key-file "payment''${ACCOUNT}-0.skey" --verification-key-file /dev/stdout | cardano-cli shelley key non-extended-key --extended-verification-key-file /dev/stdin --verification-key-file "payment''${ACCOUNT}-0.vkey"
        cardano-address key child "1852H/1815H/''${ACCOUNT}H/2/0" < "$WALLET" | cardano-cli shelley key convert-cardano-address-key --shelley-stake-key --signing-key-file /dev/stdin --out-file "stake''${ACCOUNT}.skey"
        cardano-cli shelley key verification-key --signing-key-file "stake''${ACCOUNT}.skey" --verification-key-file /dev/stdout | cardano-cli shelley key non-extended-key --extended-verification-key-file /dev/stdin --verification-key-file "stake''${ACCOUNT}.vkey"
      fi

      ADDRESS=$(cardano-cli shelley address build --payment-verification-key-file "payment''${ACCOUNT}-0.vkey" --stake-verification-key-file "stake''${ACCOUNT}.vkey" ''${NET_ARGS[@]})
    }

    function extract_utxo() {
      UTXO="$1"
      ADDRESS="$2"
      TXIN="$(jq -r --arg addr "$ADDRESS" '.[$addr].txin' < "$UTXO")"
      AMOUNT="$(jq -r --arg addr "$ADDRESS" '.[$addr].amount' < "$UTXO")"
      if [ "$AMOUNT" == "null" ]
      then
        echo "Unable to find utxo for address $ADDRESS"
        exit 1
      fi
    }
    sign_tx() {
      ACCOUNT="$1"
      WALLET="$2"
      TX="$3"
      if [ ! -f "$WALLET" ]
      then
        cardano-hw-cli shelley transaction sign --tx-body-file "''${TX}-''${ACCOUNT}.txbody" --hw-signing-file "payment''${ACCOUNT}-0.hwsfile" --hw-signing-file "stake''${ACCOUNT}.hwsfile" ''${NET_ARGS[@]} --out-file "''${TX}-''${ACCOUNT}.txsigned"
      else
        cardano-cli shelley transaction sign --tx-body-file "''${TX}-''${ACCOUNT}.txbody" --signing-key-file "payment''${ACCOUNT}-0.skey" --signing-key-file "stake''${ACCOUNT}.skey" ''${NET_ARGS[@]} --out-file "''${TX}-''${ACCOUNT}.txsigned"
      fi
    }
    witness_tx_owner() {
      ACCOUNT="$1"
      WALLET="$2"
      TX="$3"
      if [ ! -f "$WALLET" ]
      then
        cardano-hw-cli shelley transaction witness --tx-body-file "''${TX}-''${ACCOUNT}.txbody" --hw-signing-file "stake''${ACCOUNT}.hwsfile" ''${NET_ARGS[@]} --out-file "''${TX}-''${ACCOUNT}.txwitness-owner"
      else
        cardano-cli shelley transaction witness --tx-body-file "''${TX}-''${ACCOUNT}.txbody" --signing-key-file "stake''${ACCOUNT}.skey" ''${NET_ARGS[@]} --out-file "''${TX}-''${ACCOUNT}.txwitness-owner"
      fi
    }
    function pushd {
      command pushd "$@" > /dev/null
    }
    function popd {
      command popd "$@" > /dev/null
    }
  '';
  instructions = writeScriptBin "instructions" ''
    echo '
The following steps will setup pools pledging to accounts 1-10 and all rewards are sent to account 0.
1. adawallet init-restore
2. extract keys 0-10 for mainnet: `adawallet import-accounts -s 0 -e 10`
3. extract all account keys and addresses: `adawallet export-accounts --accounts-file accounts.json`
4. send resulting json to pool operator
5. Import utxo set: `adawallet import-utxos --utxo-file=utxo-mainnet-1.json`
6. register stake keys for accounts: `adawallet bulk-stake-registration-tx --ttl <TTL> --fee 200000 --out-file stake-keys.tar.gz --sign`
7. send resulting tarball to pool operator
8. pool operator returns a `pool-transactions.tar.gz` and current ttl
9. witness pool transactions with owner stake key: `adawallet bulk-witness-tx --transactions-file tx-pools.tar.gz --ttl <TTL> --stake --out-file tx-pools-witnessed.tar.gz`
10. send resulting tarball to pool operator
11. pool operator returns delegations.json and `utxo-mainnet-2.json` and current ttl
12. Import utxo set: `adawallet import-utxos --utxo-file=utxo-mainnet-2.json`
13. delegate stake keys to pools: `adawallet bulk-delegate-pool-tx --delegations delegations.json --ttl <TTL> --fee 210000 --out-file tx-deleg.tar.gz --sign`
14. send resulting tarball to pool operator

For more instructions, run `adawallet --help`
    '
  '';
  createWallet = writeScriptBin "create-wallet" ''
    ${scriptHeader}
    cardano-address recovery-phrase generate > wallet.mnemonic
    cardano-address key from-recovery-phrase Shelley < wallet.mnemonic > wallet.root_key
    echo "Your mnemonic is:"
    cat wallet.mnemonic
    printf "\n\nPlease store it somewhere secure!"
  '';
  restoreWallet = writeScriptBin "restore-wallet" ''
    ${scriptHeader}
    echo -n "Enter your 24 word mnemonic: "
    read mnemonic
    echo "$mnemonic" > wallet.mnemonic
    cardano-address key from-recovery-phrase Shelley < wallet.mnemonic > wallet.root_key
    echo "Successfully restored mnemonic"
  '';
  extractAccountKeys = writeScriptBin "extract-account-keys" ''
    ${scriptHeader}
    NAME=wallet-accounts
    function help() {
          echo "Usage: extract-account-keys -s 0 -e 20 [-t 1]"
    }
    while getopts "hs:e:t:n:w:" opt; do
      case ''${opt} in
        h)
          help; exit 0
          ;;
        s) START="$OPTARG"
          ;;
        e) END="$OPTARG"
          ;;
        n) NAME="$OPTARG"
          ;;
        t) NET_ARGS=("--testnet-magic" $OPTARG)
          ;;
        w) WALLET=$(realpath "$OPTARG")
          ;;
        \? ) help; exit 1
          ;;
        *) help; exit 1
          ;;
      esac
    done;

    if [ "$START" -lt 0 ] || [ "$END" -lt 0 ]
    then
      help; exit 1
    fi

    echo "account_index,address" > $NAME.csv
    mkdir -p "$NAME"
    pushd "$NAME"
    for i in $(seq "$START" "$END")
    do
      extract_keys "$i" "$WALLET"
      ADDRESS=$(cardano-cli shelley address build --payment-verification-key-file "payment$i-0.vkey" --stake-verification-key-file "stake$i.vkey" ''${NET_ARGS[@]})
      echo "$i,$ADDRESS" >> "$NAME.csv"
    done
    popd
    tar -czf "$NAME-stake-vkeys.tar.gz" "$NAME"/stake*.vkey "$NAME/$NAME.csv"
    mv "$NAME/$NAME.csv" ./
    echo "Successfully extracted account keys $START through $END"
    echo "A summary CSV file with list of addresses can be found in $NAME.csv"
    echo "A full tarball with keys can be found in $NAME-stake-vkeys.tar.gz"
  '';
  registerStakeKeys = writeScriptBin "register-stake-keys" ''
    ${scriptHeader}
    NAME=wallet-stake-reg
    function help() {
          echo "Usage: register-stake-keys -s 0 -e 20 -u utxo.json -l 10000000 [-t 1]"
    }
    while getopts "hs:e:t:n:l:f:u:w:" opt; do
      case ''${opt} in
        h)
          help; exit 0
          ;;
        s) START="$OPTARG"
          ;;
        e) END="$OPTARG"
          ;;
        n) NAME="$OPTARG"
          ;;
        u) UTXO="$(realpath "$OPTARG")"
          ;;
        t) NET_ARGS=("--testnet-magic" $OPTARG)
          ;;
        l) TTL="$OPTARG"
          ;;
        f) FEE="$OPTARG"
          ;;
        w) WALLET=$(realpath "$OPTARG")
          ;;
        \? ) help; exit 1
          ;;
        *) help; exit 1
          ;;
      esac
    done;

    if [ "$START" -lt 0 ] || [ "$END" -lt 0 ] || [ ! -f "$UTXO" ] || [ "$TTL" -eq 0 ]
    then
      help; exit 1
    fi

    mkdir -p "$NAME"
    pushd "$NAME"
    for i in $(seq "$START" "$END")
    do
      extract_keys "$i" "$WALLET"
      extract_utxo "$UTXO" "$ADDRESS"
      cardano-cli shelley stake-address registration-certificate --stake-verification-key-file "stake$i.vkey" --out-file "stake$i.cert"
      cardano-cli shelley transaction build-raw --tx-in "$TXIN" --tx-out "$ADDRESS+$(($AMOUNT - $FEE - 2000000))" --certificate "stake$i.cert" --ttl "$TTL" --out-file "tx-stake-reg-$i.txbody" --fee "$FEE"
      sign_tx "$i" "$WALLET" "tx-stake-reg"
    done
    popd
    tar -czf "$NAME-stake-reg.tar.gz" "$NAME"/tx-stake-reg*.txsigned
    echo "Successfully created stake key registration certificates for accounts $START through $END"
    echo "A full tarball with signed transactions can be found in $NAME-stake-reg.tar.gz"
  '';
  delegateStakeKeys = writeScriptBin "delegate-stake-keys" ''
    ${scriptHeader}
    NAME=wallet-deleg
    function help() {
          echo "Usage: delegate-stake-keys -s 0 -e 20 -u utxo.json -l 10000000 [-t 1] [-f 180000] -p pool-keys.tar.gz"
    }
    while getopts "hs:e:t:n:l:f:u:p:w:" opt; do
      case ''${opt} in
        h)
          help; exit 0
          ;;
        s) START="$OPTARG"
          ;;
        e) END="$OPTARG"
          ;;
        n) NAME="$OPTARG"
          ;;
        u) UTXO=$(realpath "$OPTARG")
          ;;
        t) NET_ARGS=("--testnet-magic" "$OPTARG")
          ;;
        l) TTL="$OPTARG"
          ;;
        f) FEE="$OPTARG"
          ;;
        p) POOLS=$(realpath "$OPTARG")
          ;;
        w) WALLET=$(realpath "$OPTARG")
          ;;
        \? ) help; exit 1
          ;;
        *) help; exit 1
          ;;
      esac
    done;

    if [ "$START" -lt 0 ] || [ "$END" -lt 0 ] || [ ! -f "$UTXO" ] || [ "$TTL" -eq 0 ] || [ ! -f "$POOLS" ]
    then
      help; exit 1
    fi

    mkdir -p "$NAME"
    pushd "$NAME"
    tar -zxf "$POOLS"
    for i in $(seq "$START" "$END")
    do
      if [ ! -f "pool$i.vkey" ]
      then
        echo "No pool key provided for account $i"
        exit 1
      fi
      extract_keys "$i" "$WALLET"
      extract_utxo "$UTXO" "$ADDRESS"
      cardano-cli shelley stake-address delegation-certificate --stake-verification-key-file "stake$i.vkey" --cold-verification-key-file "pool$i.vkey" --out-file "stake$i-deleg.cert"
      cardano-cli shelley transaction build-raw --tx-in "$TXIN" --tx-out "$ADDRESS+$(($AMOUNT - $FEE))" --certificate "stake$i-deleg.cert" --ttl "$TTL" --out-file "tx-stake-deleg-$i.txbody" --fee "$FEE"
      sign_tx "$i" "$WALLET" "tx-stake-deleg"
    done
    popd
    tar -czf "$NAME-stake-deleg.tar.gz" "$NAME"/tx-stake-deleg*.txsigned
    echo "Successfully created stake key delegation certificates for accounts $START through $END"
    echo "A full tarball with signed transactions can be found in $NAME-stake-deleg.tar.gz"
  '';
  witnessPoolTransactions = writeScriptBin "witness-pool-transactions" ''
    ${scriptHeader}
    NAME=wallet-pool
    function help() {
          echo "Usage: witness-pools-transactions -s 0 -e 20 [-t 1] -p pool-transactions.tar.gz"
    }
    while getopts "hs:e:t:n:p:w:" opt; do
      case ''${opt} in
        h)
          help; exit 0
          ;;
        s) START="$OPTARG"
          ;;
        e) END="$OPTARG"
          ;;
        n) NAME="$OPTARG"
          ;;
        t) NET_ARGS=("--testnet-magic" "$OPTARG")
          ;;
        p) POOLS=$(realpath "$OPTARG")
          ;;
        w) WALLET=$(realpath "$OPTARG")
          ;;
        \? ) help; exit 1
          ;;
        *) help; exit 1
          ;;
      esac
    done;

    if [ "$START" -lt 0 ] || [ "$END" -lt 0 ] || [ ! -f "$POOLS" ]
    then
      help; exit 1
    fi

    mkdir -p "$NAME"
    pushd "$NAME"
    tar -zxf "$POOLS"
    for i in $(seq "$START" "$END")
    do
      if [ ! -f "tx-pool-$i.txbody" ]
      then
        echo "No pool transaction provided for account $i"
        exit 1
      fi
      extract_keys "$i" "$WALLET"
      witness_tx_owner "$i" "$WALLET" "tx-pool"
    done
    popd
    tar -czf "$NAME-pool-reg.tar.gz" "$NAME"/tx-pool*.txwitness-owner
    echo "Successfully witnessed stake pools as an owner for accounts $START through $END"
    echo "A full tarball with signed transactions can be found in $NAME-pool-reg.tar.gz"
  '';
  signPaymentTx = writeScriptBin "sign-payment-tx" ''
    ${scriptHeader}
    function help() {
          echo "Usage: sign-payment-tx -a 0 [-t 1] -i tx1.txbody"
    }
    while getopts "ha:t:i:w:" opt; do
      case ''${opt} in
        h)
          help; exit 0
          ;;
        a) ACCOUNT="$OPTARG"
          ;;
        i) INPUT="$OPTARG"
          ;;
        t) NET_ARGS=("--testnet-magic" "$OPTARG")
          ;;
        w) WALLET=$(realpath "$OPTARG")
          ;;
        \? ) help; exit 1
          ;;
        *) help; exit 1
          ;;
      esac
    done;

    if [ "$ACCOUNT" -lt 0 ]
    then
      help; exit 1
    fi

    extract_keys "$ACCOUNT" "$WALLET"
    TXNAME=$(basename "$INPUT" .txbody)
    cp "$TXNAME.txbody" "$TXNAME-$ACCOUNT.txbody"
    sign_tx "$ACCOUNT" "$WALLET" "$TXNAME"
    mv "$TXNAME-$ACCOUNT.txsigned" "$TXNAME.txsigned"
    echo "signed tx output at $TXNAME.txsigned"
  '';
  createTx = writeScriptBin "create-tx" ''
    ${scriptHeader}
    function help() {
          echo "Usage: create-tx -a 0 [-t 1] -u utxo.json -r addr1abc123 -m 5000000 -l 5000"
    }
    UTXO=0
    TTL=0
    FEE=180000
    while getopts "ha:t:u:r:l:f:m:w:" opt; do
      case ''${opt} in
        h)
          help; exit 0
          ;;
        a) ACCOUNT="$OPTARG"
          ;;
        l) TTL="$OPTARG"
          ;;
        m) RAMOUNT="$OPTARG"
          ;;
        f) FEE="$OPTARG"
          ;;
        u) UTXO="$(realpath "$OPTARG")"
          ;;
        r) RECIPIENT="$OPTARG"
          ;;
        t) NET_ARGS=("--testnet-magic" "$OPTARG")
          ;;
        w) WALLET=$(realpath "$OPTARG")
          ;;
        \? ) help; exit 1
          ;;
        *) help; exit 1
          ;;
      esac
    done;

    if [ "$ACCOUNT" -lt 0 ] || [ ! -f "$UTXO" ] || [ "$TTL" -eq 0 ] || [ "$RAMOUNT" -eq 0 ]
    then
      help; exit 1
    fi

    extract_keys "$ACCOUNT" "$WALLET"
    extract_utxo "$UTXO" "$ADDRESS"
    cardano-cli shelley transaction build-raw --tx-in "$TXIN" --tx-out "$ADDRESS+$(($AMOUNT - $RAMOUNT - $FEE))" --tx-out "$RECIPIENT+$RAMOUNT" --ttl "$TTL" --out-file "tx-payment-$ACCOUNT.txbody" --fee "$FEE"
    sign_tx "$ACCOUNT" "$WALLET" "tx-payment"
    echo "signed tx output at tx-payment-$ACCOUNT.txsigned"
  '';
in {
  inherit instructions extractAccountKeys registerStakeKeys delegateStakeKeys witnessPoolTransactions createWallet restoreWallet signPaymentTx createTx;
}
