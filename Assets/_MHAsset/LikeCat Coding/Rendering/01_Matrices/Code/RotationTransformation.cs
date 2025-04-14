using System.Drawing;
using UnityEngine;

namespace MH.Matrices 
{ 
    public class RotationTransformation : Transformation
    {
        public Vector3 rotation;

        //public override Vector3 Apply(Vector3 point)
        //{
        //    //So we start by computing the sine and cosine of the desired rotation around the Z axis
        //    //We provide the angles in degrees, but the sine and cosine work with radians, so we have to convert.

        //    float radX = rotation.x * Mathf.Deg2Rad;
        //    float radY = rotation.y * Mathf.Deg2Rad;
        //    // Mathf.Deg2Rad = 2 * pi / 360
        //    // rotation.z = angle of Z axis 
        //    // ---> radZ is convert from degrees to radians
        //    float radZ = rotation.z * Mathf.Deg2Rad;

        //    float sinX = Mathf.Sin(radX);
        //    float cosX = Mathf.Cos(radX);
        //    float sinY = Mathf.Sin(radY);
        //    float cosY = Mathf.Cos(radY);
        //    float sinZ = Mathf.Sin(radZ);
        //    float cosZ = Mathf.Cos(radZ);

        //    //return point;

        //    //return new Vector3(
        //    //    point.x * cosZ - point.y * sinZ,
        //    //    point.x * sinZ + point.y * cosZ,
        //    //    point.z
        //    //);

        //    Vector3 xAxis = new Vector3(
        //    cosY * cosZ,
        //    cosX * sinZ + sinX * sinY * cosZ,
        //    sinX * sinZ - cosX * sinY * cosZ
        //    );
        //    Vector3 yAxis = new Vector3(
        //        -cosY * sinZ,
        //        cosX * cosZ - sinX * sinY * sinZ,
        //        sinX * cosZ + cosX * sinY * sinZ
        //    );
        //    Vector3 zAxis = new Vector3(
        //        sinY,
        //        -sinX * cosY,
        //        cosX * cosY
        //    );

        //    return xAxis * point.x + yAxis * point.y + zAxis * point.z;
        //}

        public override Matrix4x4 Matrix
        {
            get
            {
                float radX = rotation.x * Mathf.Deg2Rad;
                float radY = rotation.y * Mathf.Deg2Rad;
                float radZ = rotation.z * Mathf.Deg2Rad;
                float sinX = Mathf.Sin(radX);
                float cosX = Mathf.Cos(radX);
                float sinY = Mathf.Sin(radY);
                float cosY = Mathf.Cos(radY);
                float sinZ = Mathf.Sin(radZ);
                float cosZ = Mathf.Cos(radZ);

                Matrix4x4 matrix = new Matrix4x4();
                matrix.SetColumn(0, new Vector4(
                    cosY * cosZ,
                    cosX * sinZ + sinX * sinY * cosZ,
                    sinX * sinZ - cosX * sinY * cosZ,
                    0f
                ));
                matrix.SetColumn(1, new Vector4(
                    -cosY * sinZ,
                    cosX * cosZ - sinX * sinY * sinZ,
                    sinX * cosZ + cosX * sinY * sinZ,
                    0f
                ));
                matrix.SetColumn(2, new Vector4(
                    sinY,
                    -sinX * cosY,
                    cosX * cosY,
                    0f
                ));
                matrix.SetColumn(3, new Vector4(0f, 0f, 0f, 1f));
                return matrix;
            }
        }

    }
}
