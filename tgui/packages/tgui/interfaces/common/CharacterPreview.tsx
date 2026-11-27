import { ByondUi } from 'tgui-core/components';

type Props = {
  height: string;
  id: string;
  zoom?: number;
};

export const CharacterPreview = (props: Props) => {
  return (
    <ByondUi
      width="220px"
      height={props.height}
      params={{
        id: props.id,
        type: 'map',
        zoom: props.zoom ?? 0,
      }}
    />
  );
};
