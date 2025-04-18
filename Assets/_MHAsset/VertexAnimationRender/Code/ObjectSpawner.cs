using UnityEngine;

namespace MH
{
    public class ObjectSpawner : MonoBehaviour
    {
        public int TotalCount;
        public GameObject Prefab;
        public float Radius;

        private void Start()
        {
            SpawnObjects();
        }

        private void SpawnObjects()
        {
            for (int i = 0; i < TotalCount; i++)
            {
                Vector3 position = transform.position + Random.insideUnitSphere * Radius;
                Instantiate(Prefab, position, Quaternion.identity, transform);
            }
        }
        
        
    }
}