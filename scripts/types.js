// @flow
export type Patch = {
  op: string,
  value:
    | string
    /** keybindingsmenu.config.patch */
    | {
        [key: string]: string,
      },
  path: string,
  source?: string,
};
