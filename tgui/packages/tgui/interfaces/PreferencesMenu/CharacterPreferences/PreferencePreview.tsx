type Props = {
  height: string;
  image: string | null;
  size: number;
};

export function PreferencePreview({ height, image, size }: Props) {
  return (
    <div
      style={{
        display: 'grid',
        placeItems: 'center',
        backgroundColor: 'black',
        width: '220px',
        height,
      }}
    >
      {image && (
        <img
          alt="Character preview"
          src={`data:image/png;base64,${image}`}
          style={{
            width: size,
            height: size,
            maxHeight: '100%',
            objectFit: 'contain',
            imageRendering: 'pixelated',
          }}
        />
      )}
    </div>
  );
}
