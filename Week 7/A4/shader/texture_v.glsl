#version 120

precision mediump float;
const int N_LIGHTS = 1;
uniform float ambient, diffusivity, specularity, smoothness;
uniform vec4 light_positions_or_vectors[N_LIGHTS], light_colors[N_LIGHTS];
uniform float light_attenuation_factors[N_LIGHTS];
uniform vec4 shape_color;
uniform vec3 squared_scale, camera_center;

// Specifier "varying" means a variable's final value will be passed from the vertex shader
// on to the next phase (fragment shader), then interpolated per-fragment, weighted by the
// pixel fragment's proximity to each of the 3 vertices (barycentric interpolation).
varying vec3 N, vertex_worldspace;
// ***** PHONG SHADING HAPPENS HERE: *****
vec3 phong_model_lights( vec3 N, vec3 vertex_worldspace ){
    // phong_model_lights():  Add up the lights' contributions.
    vec3 E = normalize( camera_center - vertex_worldspace );
    vec3 result = vec3( 0.0 );
    for(int i = 0; i < N_LIGHTS; i++){
        // Lights store homogeneous coords - either a position or vector.  If w is 0, the
        // light will appear directional (uniform direction from all points), and we
        // simply obtain a vector towards the light by directly using the stored value.
        // Otherwise if w is 1 it will appear as a point light -- compute the vector to
        // the point light's location from the current surface point.  In either case,
        // fade (attenuate) the light as the vector needed to reach it gets longer.
        vec3 surface_to_light_vector = light_positions_or_vectors[i].xyz -
        light_positions_or_vectors[i].w * vertex_worldspace;
        float distance_to_light = length( surface_to_light_vector );

        vec3 L = normalize( surface_to_light_vector );
        vec3 H = normalize( L + E );
        // Compute the diffuse and specular components from the Phong
        // Reflection Model, using Blinn's "halfway vector" method:
        float diffuse  =      max( dot( N, L ), 0.0 );
        float specular = pow( max( dot( N, H ), 0.0 ), smoothness );
        float attenuation = 1.0 / (1.0 + light_attenuation_factors[i] * distance_to_light * distance_to_light );

        vec3 light_contribution = shape_color.xyz * light_colors[i].xyz * diffusivity * diffuse
        + light_colors[i].xyz * specularity * specular;
        result += attenuation * light_contribution;
    }
    return result;
}

varying vec2 f_tex_coord;
attribute vec3 position, normal;
// Position is expressed in object coordinates.
attribute vec2 texture_coord;

uniform mat4 model_transform;
uniform mat4 projection_camera_model_transform;

void main(){
    // The vertex's final resting place (in NDCS):
    gl_Position = projection_camera_model_transform * vec4( position, 1.0 );
    // The final normal vector in screen space.
    N = normalize( mat3( model_transform ) * normal / squared_scale);
    vertex_worldspace = ( model_transform * vec4( position, 1.0 ) ).xyz;
    // Turn the per-vertex texture coordinate into an interpolated variable.
    f_tex_coord = texture_coord;
}