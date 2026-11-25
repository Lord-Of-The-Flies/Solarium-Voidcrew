/**
 * Fallback for the private Horusheresy TGUI package.
 *
 * Used when the Horusheresy submodule is not checked out. rspack swaps the
 * `solarium_tgui` alias to this package, and every lookup simply falls through
 * to the public voidcrew/core interface loaders in tgui/packages/tgui/routes.tsx.
 */
export const loadInterface = (_interfacePath) => null;
