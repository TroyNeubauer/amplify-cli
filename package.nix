{ lib
, stdenv
, src
, gitMinimal
, yarn
, makeBinaryWrapper
, nodejs
, python3
}:

let
  version = "1.9.9";

  # we cannot use fetchYarnDeps because that doesn't support yarn 2/berry lockfiles
  offlineCache = stdenv.mkDerivation {
    name = "aws-amplify-${version}-offline-cache";
    inherit src;

    nativeBuildInputs = [
      # cacert # needed for git
      gitMinimal # needed to download git dependencies
      nodejs # needed for npm to download git dependencies
      yarn
    ];

    buildPhase = ''
      export HOME=$(mktemp -d)
      yarn config set enableTelemetry 0
      yarn config set cacheFolder $out
      # yarn config set strict-ssl false
      yarn config set --json supportedArchitectures.os '[ "linux" ]'
      yarn config set --json supportedArchitectures.cpu '["arm", "arm64", "ia32", "x64"]'
      echo "STARTING yarn"
      yarn --version
      exit 1
      yarn config set enableStrictSsl false
      yarn
      echo "downloaded deps"
    '';

    outputHashMode = "recursive";
    outputHash = "sha256-Ga+tl4oZlum43tdfez1oWGMHZAfyePGl47S+9NRRvW8=";
  };

in stdenv.mkDerivation {
  pname = "aws-amplify";
  inherit version src;

  nativeBuildInputs = [
    makeBinaryWrapper
    yarn
    python3 # needed for sqlite node-gyp
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    yarn config set enableTelemetry 0
    yarn config set cacheFolder ${offlineCache}

    # This will fail but create the sqlite3 files we can patch
    yarn --immutable-cache || :

    # Ensure we don't download any node things
    sed -i 's:--fallback-to-build:--build-from-source --nodedir=${nodejs}/include/node:g' node_modules/sqlite3/package.json
    export CPPFLAGS="-I${nodejs}/include/node"

    # Perform the actual install
    yarn --immutable-cache
    yarn run build

    patchShebangs bin/*

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    echo "Installing in: " $out
    mkdir -p $out
    cp -R {app.js,bin,lib,locales,node_modules,package.json,public} $out

    makeWrapper ${nodejs}/bin/node $out/bin/hedgedoc \
      --add-flags $out/app.js \
      --set NODE_ENV production \
      --set NODE_PATH "$out/lib/node_modules"

    runHook postInstall
  '';

  meta = {
    description = "Realtime collaborative markdown notes on all platforms";
    license = lib.licenses.agpl3;
    homepage = "https://hedgedoc.org";
    mainProgram = "hedgedoc";
    maintainers = with lib.maintainers; [ SuperSandro2000 ];
    platforms = lib.platforms.linux;
  };
}
