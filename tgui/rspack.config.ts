import fs from 'node:fs';
import path from 'node:path';

import { defineConfig } from '@rspack/cli';
import rspack, { type StatsOptions } from '@rspack/core';

export function createStats(verbose: boolean): StatsOptions {
  return {
    assets: verbose,
    builtAt: verbose,
    cached: false,
    children: false,
    chunks: false,
    colors: true,
    entrypoints: true,
    hash: false,
    modules: false,
    performance: false,
    timings: verbose,
    version: verbose,
  };
}

const dirname = path.resolve();

// Solarium: private Horusheresy TGUI interfaces live in a submodule. When it is
// not checked out, resolve the same import to a local no-op loader so the core
// build works without the submodule.
const solariumTguiPath = path.resolve(
  dirname,
  '../Horusheresy/tgui/packages/solarium_tgui',
);
const solariumTguiFallbackPath = path.resolve(
  dirname,
  './packages/solarium_tgui_fallback',
);

export default defineConfig({
  context: dirname,
  devtool: false,
  entry: {
    tgui: './packages/tgui',
    'tgui-panel': './packages/tgui-panel',
    'tgui-say': './packages/tgui-say',
  },
  mode: 'production',
  module: {
    rules: [
      {
        test: /\.([tj]s(x)?|cjs)$/,
        type: 'javascript/auto',
        use: [
          {
            loader: 'builtin:swc-loader',
            options: {
              jsc: {
                parser: {
                  syntax: 'typescript',
                  tsx: true,
                },
                transform: {
                  react: {
                    runtime: 'automatic',
                  },
                },
              },
            },
          },
        ],
      },
      {
        test: /\.(s)?css$/,
        type: 'javascript/auto',
        use: [
          rspack.CssExtractRspackPlugin.loader,
          'css-loader',
          {
            loader: 'sass-loader',
            options: {
              api: 'modern-compiler',
              implementation: 'sass-embedded',
            },
          },
        ],
      },
      {
        test: /\.(png|jpg)$/,
        type: 'asset/resource',
        generator: {
          filename: '[name][ext]',
        },
      },

      {
        // Inline SVGs: the game serves TGUI from an asset-cache URL, so a
        // site-root URL like /bg-nanotrasen.svg is a 404 in-game. Data URIs
        // keep emblems working in every transport, including browse_rsc.
        test: /\.svg$/,
        type: 'asset/inline',
      },
    ],
  },
  optimization: {
    emitOnErrors: false,
  },
  output: {
    path: 'public',
    filename: '[name].bundle.js',
    chunkFilename: '[name].bundle.js',
    chunkLoadTimeout: 15000,
    publicPath: '/',
    assetModuleFilename: '[name][ext]',
  },
  performance: {
    hints: false,
  },
  plugins: [
    new rspack.CssExtractRspackPlugin({
      chunkFilename: '[name].bundle.css',
      filename: '[name].bundle.css',
    }),
    new rspack.EnvironmentPlugin({
      NODE_ENV: 'production',
    }),
  ],
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.jsx'],
    // Private interfaces live outside tgui/ (Horusheresy submodule), so make
    // the workspace node_modules resolvable from any issuer path.
    modules: [path.resolve(dirname, './node_modules'), 'node_modules'],
    alias: {
      tgui: path.resolve(dirname, './packages/tgui'),
      'tgui-panel': path.resolve(dirname, './packages/tgui-panel'),
      'tgui-say': path.resolve(dirname, './packages/tgui-say'),
      'tgui-dev-server': path.resolve(dirname, './packages/tgui-dev-server'),
      solarium_tgui: fs.existsSync(solariumTguiPath)
        ? solariumTguiPath
        : solariumTguiFallbackPath,
    },
  },
  stats: createStats(true),
  target: ['web', 'browserslist:edge >= 123'],
});
