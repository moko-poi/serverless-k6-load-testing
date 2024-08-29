# Serverless K6 Load Testing

このリポジトリは、AWS Lambda上でk6を使用したサーバーレス負荷試験の設定および実行方法を提供します。Terraformを使用してインフラストラクチャを管理し、Lambda関数をデプロイすることで、手軽に分散負荷試験を行うことが可能です。

## ディレクトリ構造

```
├── README.md
├── lambda
│   ├── k6_lambda.zip
│   └── src
│       ├── bootstrap
│       ├── jq
│       ├── k6
│       └── simple.js
└── terraform
    ├── main.tf
    ├── terraform.tfstate
    └── terraform.tfstate.backup
```

### `lambda/`
このディレクトリには、AWS Lambda関数として実行されるk6のコードとその依存ファイルが含まれています。

- `k6_lambda.zip`: Lambda関数としてデプロイされるアーカイブファイル。このファイルには、`src/`ディレクトリの内容が含まれています。
- `src/`: Lambda関数の実行に必要なファイル群。
  - `bootstrap`: Lambda関数が実行される際のエントリーポイントとなるスクリプト。
  - `jq`: JSON処理ツール。このプロジェクトでは、k6の実行結果を加工するために使用します。
  - `k6`: k6の実行バイナリファイル。
  - `simple.js`: 実際にk6で実行される負荷試験のスクリプト。このスクリプトにより、指定したターゲットに対する負荷試験を実行します。

### `terraform/`
このディレクトリには、AWSインフラストラクチャを構築するためのTerraform設定ファイルが含まれています。

- `main.tf`: AWSリソースを定義するTerraformのメイン構成ファイル。Lambda関数のデプロイ、IAMロールの設定、その他必要なリソースの作成が記述されています。
- `terraform.tfstate`: 現在のインフラストラクチャの状態を管理するためのファイル。このファイルにより、Terraformはリソースの変更を適切に適用します。
- `terraform.tfstate.backup`: `terraform.tfstate`のバックアップファイル。

## 使い方

1. **Terraformによるインフラ構築**:
    - `terraform`ディレクトリに移動し、Terraformを実行してインフラをデプロイします。
    - 以下のコマンドを使用してインフラをデプロイします:
      ```bash
      terraform init
      terraform apply
      ```

2. **Lambda関数のデプロイ**:
    - `lambda/k6_lambda.zip` ファイルを用意し、TerraformによってLambda関数としてデプロイされます。

3. **負荷試験の実行**:
    - デプロイされたLambda関数がk6を実行し、ターゲットに対する負荷試験を開始します。
    - 結果はCloudWatchに送信され、後で分析することが可能です。
