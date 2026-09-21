# 再現用リポジトリの使い方

このリポジトリは、論文 **“Image-Based Correction-Collar Optimization over Time in In Vivo Two-Photon Microscopy”** の Figure 1–4 に対応する数値解析を、コンパクトなanalysis-ready datasetから再計算するためのものです。

## 何を入力にするか

再現コードは、すでに計算済みの `CC_NaN`、θopt、W95、relative fitted score、DiffMADなどを入力にはしません。

入力は、各時点・各補正環角度で得られた **正規化済み実測Peak-F** と、角度・深度・条件・時点・segment IDなどの最低限のmetadataです。

公開時には `data/analysis_ready/` に以下の2ファイルを置きます。

```text
Figure1_analysis_ready.mat
Figures2to4_analysis_ready.mat
```

これらは `code/builders/` の2本のbuilderから作成できます。

## 一括実行

MATLABでrepository rootをcurrent folderにして、

```matlab
setup_repository
run_all_reproductions
```

を実行します。

結果は

```text
results/reproduced/Figure1
results/reproduced/Figure2
results/reproduced/Figure3
results/reproduced/Figure4
```

に保存されます。

その後、

```matlab
validate_against_verified
```

を実行すると、主要な出力CSVを、今回すでにSource Dataと照合済みのreference CSVと比較できます。

## 解析定義の重要点

- Peak-Fは各時点で実測最大値を1として正規化します。
- 14角度の値に3次多項式をfitします。
- fitはsampled-angle index上で行い、0.01 index刻みで評価します。2°刻みの実験では0.02°刻みに相当します。
- 実測Peak-F最大値がscan内部ならfine-grid fitted maximumをθoptとして使います。
- 実測最大値がscan端なら、その実測boundary angleをoperational θoptとして保持します。
- R² > 0.7をvalid fitとし、R² ≤ 0.7のθoptはNaNにします。
- boundary hitは **実測Peak-F最大値** がscan端にある場合です。
- W95はR² validity maskとは独立に集計します。
- Fig.3のθrefだけは、1%・200 µmにおける最初のvalid **fitted optimum**を使い、boundary fallback前の値です。
- DiffMADはsigned first differenceのMADです。Fig.4Dの|Δθopt|表示とは区別します。
- 0%条件の3つの10点blockをまたぐ差分やlongest runは計算しません。
- LMEはMLでfitし、0%をreference categoryにします。

詳細は `ANALYSIS_DEFINITIONS.md` を参照してください。

## Source Dataとの関係

`data/source_data/` のxlsxは論文のSource Dataであり、再現コードの入力ではありません。

再現の流れは、

```text
analysis-ready normalized Peak-F
        ↓
再現コード
        ↓
新しく計算したCSV
        ↓
Source Data / verified_key_outputsと照合
```

です。

## standalone版と共通関数版

`code/verified_standalone/` には、今回Figure 1–4について実際にSource Dataとの一致を確認したstandalone版を残しています。

`code/reproduction/` はそれらをrepository向けに共通関数化した版で、`code/functions/+ccrepro/` のfit・統計utilityを共有します。

公開前の最終確認では、共通関数版を一括実行した後、`validate_against_verified`がすべてPASSになることを確認してください。


## MATLAB path エラーが出る場合

`setup_repository` 実行後には、repository root に加えて `ccrepro.get_param` の解決先が表示されます。次でも確認できます。

```matlab
which ccrepro.get_param -all
```

`code/functions/+ccrepro/get_param.m` が表示されれば正常です。0.1.2-draft では、MATLAB のバージョンによって `exist('pkg.func','file')` が `+package` 関数を正しく検出しないことがあるため、package 検出を `which` に変更しました。

それでも解決しない場合は repository root で次を実行してください。

```matlab
restoredefaultpath
rehash toolboxcache
setup_repository(pwd)
which ccrepro.get_param -all
```

`restoredefaultpath` はその MATLAB セッションで追加した他のカスタム path も解除するため、必要なものはその後に再追加してください。


## 実行場所について

推奨方法は、リポジトリのルートを MATLAB の Current Folder にして、

```matlab
setup_repository
run_all_reproductions
validate_against_verified
```

を順に実行する方法です。v0.1.3 以降ではエントリーポイントがリポジトリ位置を自己解決するため、別の Current Folder からフルパスで `run(...)` しても動作するようにしています。

## 図パネルの再生成

数値再現とは別に、`data/source_data/` の公開用Source Data workbookから主図のデータパネルをSVG/PNGで再生成できます。

```matlab
setup_repository
generate_all_main_figure_panels
```

出力先は `results/figure_panels/Figure1` ～ `Figure4` です。図生成コードは可視化のみを行い、統計検定を再計算しません。最終的な複合図のパネル配置・パネル文字・模式図の仕上げはIllustratorで行うことを想定しています。

Figure 1Cの代表蛍光画像は、このコンパクトな数値再現パッケージに画像本体が含まれていないため自動生成しません。必要な時点・角度はSource Dataのmetadataに記録されています。

公開向けの図ラベルとREADMEでは原則として `normalized image score` / `spatial-frequency-based image score` を使い、`Peak-F` は既報およびlegacy codeとの対応を説明する場合に限って使用します。


## ライセンスと引用

- MATLABコード: MIT License (`LICENSE`)
- データ、検証済み出力、ドキュメント、生成されたデータ図: CC BY 4.0 (`LICENSE_DATA.md`)
- 機械可読な引用情報: `CITATION.cff`

公開時にはGitHub URLとZenodo DOIをREADMEおよび`CITATION.cff`に追加します。論文DOIが確定した後は、論文を`preferred-citation`として`CITATION.cff`に追記する予定です。

論文本文に記載するData and code availability文案は `docs/DATA_CODE_AVAILABILITY.md` にあります。
