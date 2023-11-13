//
//  FMGeometry.m
//  fmkit
//
//  Created by August Mueller on 7/12/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "FMGeometry.h"



CGPoint FMRandomPointInTriangle(CGPoint A, CGPoint B, CGPoint C) {
    
    float s = (float)random() / (float) LONG_MAX;
    float t = (float)random() / (float) LONG_MAX;
    
    CGPoint a;
    CGPoint b;
    CGPoint c;
    
    a.x = (1 - sqrt(t));
    a.y = (1 - sqrt(t));
    
    b.x = (1 - s)*sqrt(t);
    b.y = (1 - s)*sqrt(t);
    
    c.x = (s*sqrt(t));
    c.y = (s*sqrt(t));
    
    return CGPointMake((a.x * A.x) + (b.x * B.x) + (c.x * C.x),
                       (a.y * A.y) + (b.y * B.y) + (c.y * C.y));
}

float FMGetAngleBetweenPoints(CGPoint a, CGPoint b) {
    float   dx      = b.x - a.x;
    float   dy      = b.y - a.y;
    float   angle   = 0.0;
    
        // Calculate angle
    if (dx == 0.0) {
        
        if (dy == 0.0)
            angle = 0.0;
        else if (dy > 0.0)
            angle = M_PI / 2.0;
        else
            angle = M_PI * 3.0 / 2.0;
    }
    else if (dy == 0.0) {
        
        if  (dx > 0.0)
            angle = 0.0;
        else
            angle = M_PI;
    }
    else {
        if  (dx < 0.0)
            angle = atan(dy/dx) + M_PI;
        else if (dy < 0.0)
            angle = atan(dy/dx) + (2 * M_PI);
        else
            angle = atan(dy/dx);
    }
    
    // Convert to degrees
    angle = angle * 180.0f / M_PI;
    
    return angle;
}


float FMDistanceBetweenPoints(CGPoint a, CGPoint b) {
    
    float xd = b.x - a.x;
    float yd = b.y - a.y;
    
    return sqrtf((xd * xd) + (yd * yd));
}

CGPoint FMPointMidpoint( CGPoint a, CGPoint b )  {
    return CGPointMake( 0.5f * ( a.x + b.x ), 0.5f * ( a.y + b.y ) );
}

// shamelessly stolen from usenet.
// http://groups-beta.google.com/group/rec.games.programmer/browse_thread/thread/c6293a0abc9ec53/3cfbfc893bf977e9?lnk=st&q=intersection_line_2_line_pos&rnum=1&hl=en#3cfbfc893bf977e9

BOOL FMLinesIntersectAtPoint(FMLineSegment *s1, FMLineSegment *s2, CGPoint *p) {
    int dx2, dy2, dx1, dy1, 
    dx12, dy12, a, b, 
    a_flag=0, b_flag=0; 
    (void)(dy1 = s1->q.y-s1->p.y), dx1 = s1->q.x-s1->p.x;
    (void)(dy2 = s2->q.y-s2->p.y), dx2 = s2->q.x-s2->p.x;
    (void)(dy12= s2->p.y-s1->p.y), dx12= s2->p.x-s1->p.x;
    if ((b=dy2*dx1-dx2*dy1)  == 0) return FALSE; 
    if ( b < 0) (void)(b = -b),b_flag=1; 
    if ( (a=dy2*dx12-dx2*dy12) < 0) (void)(a = -a),a_flag=1; 
    if ( a>b || (a_flag ^ b_flag)) return FALSE; 
    if ( (a=dx1*dy12-dy1*dx12) < 0) (void)(a=-a),a_flag=0; 
    else a_flag=1; 
    if ( a>b || (a_flag ^ b_flag)) return FALSE; 
    p->x = s2->p.x + dx2*a/b; 
    p->y = s2->p.y + dy2*a/b; 
    return TRUE; 
    
} 
