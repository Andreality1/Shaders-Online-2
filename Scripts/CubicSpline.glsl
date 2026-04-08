  #define CATMULL_ROM 0

        #define BEZIER 1

        

        vec2[] pts = vec2[](

            vec2(0.1,0.2),

            vec2(0.5,0.1),

            vec2(0.2,-0.3),

            vec2(-0.2,0.2),

            vec2(-0.4,0.2),

            vec2(-0.5,0.4),

            vec2(-0.6,-0.2),

            vec2(-0.8,-0.3),

            vec2(-0.3,-0.4),

            vec2(-0.2,-0.3),

            vec2(-0.8,-0.3),

            vec2(-0.3,-0.4)

        );

        

        vec2 get_pt(int i){

            return pts[(i+pts.length())%pts.length()];

        }

        

        // Characteristic matrices

        const float[] bezier = float[16](

            1.,  0.,  0.,  0.,

            -2., 2.,  0.,  0.,

            1., -2.,  1.,  0.,

            0., 0., 0.,  0.

        );

        const float[] hermite = float[16](

            1.,  0.,  0.,  0.,

            0.,  1.,  0.,  0.,

            -3.,-2.,  3., -1.,

            2.,  1., -2.,  1.

        );

        

        

        float sdLine(vec2 uv, vec2 a, vec2 b){

            vec2 ab = b - a;

            vec2 p = a + ab*clamp(dot(uv-a, ab)/dot(ab,ab),0.,1.);

            return length(uv-p);

        }

        

        

        

        vec2 curve_sample(float[16] m, float t, vec2 P0, vec2 P1, vec2 P2, vec2 P3){

            return (P0*m[0]  + P1*m[1]  + P2*m[2]  + P3*m[3] ) +

                t*     (P0*m[4]  + P1*m[5]  + P2*m[6]  + P3*m[7] ) +

                t*t*   (P0*m[8]  + P1*m[9]  + P2*m[10] + P3*m[11]) +

                t*t*t* (P0*m[12] + P1*m[13] + P2*m[14] + P3*m[15]);

        }

        

        void draw_curve(

            inout vec3 col, vec2 uv, vec3 curve_col, float[16] m, vec2 P0, vec2 P1, vec2 P2, vec2 P3

        ){

            const float its = 44.;

            float sd_curve = 1000.;

            vec2 prev_p;

            for(float t = 0. ; t <= 1. + 0.01/its; t+=1./its){

                vec2 p = curve_sample(m,t,P0,P1,P2,P3);

        

                if(t < 0.01/its)

                    prev_p = p;

        

                sd_curve = min(sd_curve,sdLine(uv,prev_p,p) - 0.002);   

                prev_p = p;

            }

            col = mix(col,curve_col,smoothstep(fwidth(uv.y),0.,sd_curve));

        }

        

        void mainImage( out vec4 fragColor, in vec2 fragCoord ){

            vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

            vec2 muv = (iMouse.xy - 0.5*iResolution.xy)/iResolution.y;

        

            vec3 col = vec3(0.95);

            

            // Draw background

            vec2 uvb = mod(uv, 0.1) - 0.05;

            float sd_bg = 1000.;

            sd_bg = min(sd_bg,abs(uvb.x));

            sd_bg = min(sd_bg,abs(uvb.y));

            col = mix(col,vec3(0.6),smoothstep(fwidth(uv.y),0.,sd_bg));

            

            

            // Offset points

            for(float i = 0.; i < float(pts.length()); i++){

                pts[int(i)] += vec2(sin(i+iTime*cos(i)),cos(i+iTime*sin(i)))*0.2;

            }

            

            // Generate catmull rom tangents

            vec2[pts.length()] tangents;

            const float visc = 0.5;

            for(int i = 0; i < tangents.length(); i++){

                tangents[i] = (get_pt(i+1) - get_pt(i-1))*visc;

            }

            

            const vec3 bezier_col = vec3(1,0.2,0);

            const vec3 catmull_rom_col = vec3(0.1,0.5,0.);

            

            float sd_black_lines = 1000.;

            float sd_bez_stuff = 1000.;

            float sd_points = 1000.;

            

            for(int spline = 0; spline < 2 + min(iFrame,0); spline++){

                for(int pid = 0; pid < pts.length(); pid++){

                    // Get catmull rom points

                    vec2 P0 = get_pt(pid);

                    vec2 P1 = tangents[pid];

                    vec2 P2 = get_pt(pid+1);

                    vec2 P3 = tangents[(pid + 1)%tangents.length()];

                    if(spline == CATMULL_ROM){

                        // Draw

                        sd_black_lines = min(sd_black_lines,sdLine(uv,P0,P0+P1));

                        sd_black_lines = min(sd_black_lines,sdLine(uv,P2,P2+P3));

                        draw_curve(col, uv, catmull_rom_col, hermite, P0, P1, P2, P3);

                    } else if (spline == BEZIER){

                        vec2 mid_point = curve_sample(hermite,0.5,P0,P1,P2,P3); 

                        

                        P3 = vec2(0);

                        

                        // Calculate beziers

                        const float k = 0.25;

                        

                        vec2 bez_a_P0 = get_pt(pid);

                        vec2 bez_a_P1 = P0 + k*tangents[pid];

                        vec2 bez_a_P2 = mid_point;

                        

                        vec2 bez_b_P0 = mid_point;

                        vec2 bez_b_P2 = get_pt(pid+1);

                        vec2 bez_b_P1 = P2 - k*tangents[(pid+1)%tangents.length()];

                        

                        // Draw

                        draw_curve(col, uv, bezier_col, bezier, bez_a_P0, bez_a_P1, bez_a_P2, P3);

                        

                        draw_curve(col, uv, bezier_col, bezier, bez_b_P0, bez_b_P1, bez_b_P2, P3);

                        

                        sd_bez_stuff = min(sd_bez_stuff, length(bez_a_P1 - uv) - 0.01);

                        sd_bez_stuff = min(sd_bez_stuff, length(bez_b_P1 - uv) - 0.01);

                        sd_bez_stuff = min(sd_bez_stuff, sdLine(uv,bez_a_P1,mid_point));

                        sd_bez_stuff = min(sd_bez_stuff, sdLine(uv,bez_b_P1,mid_point));

                        sd_bez_stuff = min(sd_bez_stuff, sdLine(uv,bez_b_P2,P2 - k*tangents[(pid+1)%tangents.length()]));

                        

                    }

                }

            }

            

            col = mix(col,bezier_col,smoothstep(fwidth(uv.y),0.,sd_bez_stuff));

            

            for(int p = 0; p < pts.length(); p++){

                sd_points = min(sd_points,length(uv - pts[p]) - 0.01);

            }

            sd_points = min(sd_points,sd_black_lines);

            col = mix(col,vec3(0.0),smoothstep(fwidth(uv.y),0.,sd_points));

            

            

            col = pow(col,vec3(0.454545));

            fragColor = vec4(col,1.0);

        }