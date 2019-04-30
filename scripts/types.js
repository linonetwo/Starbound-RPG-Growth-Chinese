// @flow
export type Patch = {
  op: string,
  value:
    | string
    /** keybindingsmenu.config.patch */
    | Object,
  path: string,
  source?: string,
};
