
/*
 *  Panning styles for the Roaming 2D Camera.
 */
enum CameraPanningStyle
{
    VERTICAL,
    HORIZONTAL,
    DIAGONAL;
}

/*
 *  Panning styles for Vertical panning.
 */
enum VerticalPanningStyle
{
    TOBOTTOM,
    TOTOP; 
}

/*
 *  Panning styles for Horizontal panning.
 */
enum HorizontalPanningStyle
{
    TOLEFT,
    TORIGHT; 
}

/*
 *  Panning styles for Diagonal panning.
 */
enum DiagonalPanningStyle
{
    TOTOPLEFT,
    TOTOPRIGHT,
    TOBOTTOMLEFT,
    TOBOTTOMRIGHT; 
}

/* 
 *  State enum for managing camera fade status.
 */
enum CameraFadeState
{
    NO_FADE,
    FADE_IN,
    FADE_OUT;
}


