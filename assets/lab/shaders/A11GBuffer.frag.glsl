/*!*****************************************************************************
\file Assignment11GBuffer.frag.glsl
\author Yimo Kong (yimo.kong@digipen.edu)
\par Course: CSD2151
\par Assignment: 11 (Ogres)
\date 03/21/2026 (MM/DD/YYYY)
\brief
    Fragment shader for the Assignment 11 geometry pass. It writes per-fragment
    world position, geometric normal, texture coordinates, and tangent-space
    light and view vectors into the G-buffer so the fullscreen deferred stage
    can shade the scene without redrawing all Ogre instances.
*******************************************************************************/
R"(
    #version 420 core

    in vec3 WorldPosition;
    in vec3 WorldNormal;
    in vec3 TangentLightDirection;
    in vec3 TangentViewDirection;
    in vec2 TextureCoordinates;

    layout(location = 0) out vec3 GPosition;
    layout(location = 1) out vec3 GNormal;
    layout(location = 2) out vec4 GTexCoord;
    layout(location = 3) out vec4 GLightDirection;
    layout(location = 4) out vec4 GViewDirection;

    void main()
    {
        GPosition = WorldPosition;
        GNormal = normalize(WorldNormal);
        GTexCoord = vec4(TextureCoordinates, 0.0, 1.0);
        GLightDirection = vec4(TangentLightDirection, 1.0);
        GViewDirection = vec4(TangentViewDirection, 1.0);
    }
)"
