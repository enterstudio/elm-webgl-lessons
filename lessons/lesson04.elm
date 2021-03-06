module Main exposing (..)

import Color exposing (..)
import Math.Vector3 exposing (..)
import Math.Matrix4 exposing (..)
import WebGL exposing (..)
import Html exposing (Html)
import Html.App as Html
import Html.Attributes exposing (width, height, style)
import AnimationFrame


-- Create a mesh with a pyramid and a square


type alias Vertex =
    { position : Vec3, color : Vec3 }


pyramid : Drawable Vertex
pyramid =
    let
        top =
            vec3 0 1 0

        rbb =
            vec3 1 -1 -1

        rfb =
            vec3 1 -1 1

        lbb =
            vec3 -1 -1 -1

        lfb =
            vec3 -1 -1 1

        colortop =
            vec3 1 0 0

        colorlfb =
            vec3 0 1 0

        colorrfb =
            vec3 0 0 1
    in
        Triangle
            << List.concat
        <|
            [ pyramidFace colortop colorlfb colorrfb top lfb rfb
            , pyramidFace colortop colorlfb colorrfb top lfb lbb
            , pyramidFace colortop colorrfb colorlfb top rfb rbb
            , pyramidFace colortop colorlfb colorrfb top rbb lbb
            ]


pyramidFace : Vec3 -> Vec3 -> Vec3 -> Vec3 -> Vec3 -> Vec3 -> List ( Vertex, Vertex, Vertex )
pyramidFace colora colorb colorc a b c =
    [ ( Vertex a colora
      , Vertex b colorb
      , Vertex c colorc
      )
    ]


cube : Drawable Vertex
cube =
    let
        rft =
            vec3 1 1 1

        -- right, front, top
        lft =
            vec3 -1 1 1

        -- left,  front, top
        lbt =
            vec3 -1 -1 1

        rbt =
            vec3 1 -1 1

        rbb =
            vec3 1 -1 -1

        rfb =
            vec3 1 1 -1

        lfb =
            vec3 -1 1 -1

        lbb =
            vec3 -1 -1 -1
    in
        Triangle
            << List.concat
        <|
            [ cubeFace (vec3 1 0 0) rft rfb rbb rbt
              -- right
            , cubeFace (vec3 1 1 0) rft rfb lfb lft
              -- front
            , cubeFace (vec3 0 1 0) rft lft lbt rbt
              -- top
            , cubeFace (vec3 1 0.5 0.5) rfb lfb lbb rbb
              -- bottom
            , cubeFace (vec3 1 0 1) lft lfb lbb lbt
              -- left
            , cubeFace (vec3 0 0 1) rbt rbb lbb lbt
              -- back
            ]


cubeFace : Vec3 -> Vec3 -> Vec3 -> Vec3 -> Vec3 -> List ( Vertex, Vertex, Vertex )
cubeFace color a b c d =
    let
        vertex position =
            Vertex position color
    in
        [ ( vertex a, vertex b, vertex c )
        , ( vertex c, vertex d, vertex a )
        ]


main : Program Never
main =
    Html.program
        { init = ( 0, Cmd.none )
        , view = view
        , subscriptions = (\model -> AnimationFrame.diffs Basics.identity)
        , update = (\elapsed currentTime -> ( elapsed / 1000 + currentTime, Cmd.none ))
        }



-- VIEW


view : Float -> Html msg
view t =
    WebGL.toHtml
        [ width 400, height 400, style [ ( "backgroundColor", "black" ) ] ]
        ([ render vertexShader fragmentShader pyramid (uniformsPyramid t) ]
            ++ [ render vertexShader fragmentShader cube (uniformsCube t) ]
        )


uniformsPyramid : Float -> { rotation : Mat4, perspective : Mat4, camera : Mat4, displacement : Vec3 }
uniformsPyramid t =
    { rotation = makeRotate t (vec3 0 1 0)
    , perspective = makePerspective 45 1 0.01 100
    , camera = makeLookAt (vec3 0 0 10) (vec3 0 0 0) (vec3 0 1 0)
    , displacement = (vec3 -4 0 0)
    }


uniformsCube : Float -> { rotation : Mat4, perspective : Mat4, camera : Mat4, displacement : Vec3 }
uniformsCube t =
    { rotation = makeRotate t (vec3 1 1 1)
    , perspective = makePerspective 45 1 0.01 100
    , camera = makeLookAt (vec3 0 0 10) (vec3 0 0 0) (vec3 0 1 0)
    , displacement = (vec3 4 0 0)
    }



-- Shaders


vertexShader : Shader { attr | position : Vec3, color : Vec3 } { unif | rotation : Mat4, displacement : Vec3, perspective : Mat4, camera : Mat4 } { vcolor : Vec3 }
vertexShader =
    [glsl|

  precision mediump float;
  attribute vec3 position;
  attribute vec3 color;
  uniform mat4 rotation;
  uniform vec3 displacement;
  uniform mat4 perspective;
  uniform mat4 camera;
  varying vec3 vcolor;

  void main() {
    gl_Position = perspective * camera * rotation * vec4(position, 1.0) + vec4(displacement, 1);
    vcolor = color;
  }
|]


fragmentShader : Shader {} u { vcolor : Vec3 }
fragmentShader =
    [glsl|
  precision mediump float;
  varying vec3 vcolor;

  void main () {
      gl_FragColor = vec4(vcolor, 1.0);
  }

|]
