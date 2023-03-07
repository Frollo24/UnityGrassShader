using UnityEngine;
using UnityEngine.Rendering;

public class ProceduralGrass : MonoBehaviour
{
    #region EditorVariables
    [Header("Rendering Properties")]

    [Tooltip("Compute shader for generating transformation matrices.")]
    [SerializeField] private ComputeShader _computeShader;
    [Tooltip("Mesh for individual grass blades.")]
    [SerializeField] private Mesh _grassMesh;
    [Tooltip("Material for rendering each grass blade.")]
    [SerializeField] private Material _grassMaterial;
    private Mesh _terrainMesh;

    [Space(10)]

    [Header("Lighting and Shadows")]
    [Tooltip("Should the procedural grass cast shadows?")]
    [SerializeField] private ShadowCastingMode _castShadows = ShadowCastingMode.On;
    [Tooltip("Should the procedural grass receive shadows from other objects?")]
    [SerializeField] private bool _receiveShadows = true;

    [Space(10)]

    [Header("Grass Blade Properties")]
    [Tooltip("Base size of grass blades in all three axes.")]
    [SerializeField] [Range(0.0f, 1.0f)] private float _scale = 0.1f;
    [Tooltip("Minimum height multiplier.")]
    [SerializeField] [Range(0.0f, 5.0f)] private float _minBladeHeight = 0.5f;
    [Tooltip("Maximum height multiplier.")]
    [SerializeField] [Range(0.0f, 5.0f)] private float _maxBladeHeight = 1.5f;
    [Tooltip("Minimum random offset in the x- and z-directions.")]
    [SerializeField] [Range(-1.0f, 1.0f)] private float _minOffset = -0.1f;
    [Tooltip("Maximum random offset in the x- and z-directions.")]
    [SerializeField] [Range(-1.0f, 1.0f)] private float _maxOffset = 0.1f;
    #endregion

    #region Rendering Elements
    private int _kernel;
    private int _terrainTriangleCount = 0;

    private GraphicsBuffer _terrainTriangleBuffer;
    private GraphicsBuffer _terrainVertexBuffer;
    private GraphicsBuffer _transformMatrixBuffer;

    private GraphicsBuffer _grassTriangleBuffer;
    private GraphicsBuffer _grassVertexBuffer;
    private GraphicsBuffer _grassUVBuffer;

    private Bounds _bounds;
    private MaterialPropertyBlock _properties;
    #endregion

    #region MonoBehaviour
    private void Start()
    {
        _kernel = _computeShader.FindKernel("CSMain");

        _terrainMesh = GetComponent<MeshFilter>().sharedMesh;

        // Terrain data for the compute shader.
        Vector3[] terrainVertices = _terrainMesh.vertices;
        _terrainVertexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, terrainVertices.Length, sizeof(float) * 3);
        _terrainVertexBuffer.SetData(terrainVertices);

        int[] terrainTriangles = _terrainMesh.triangles;
        _terrainTriangleBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, terrainTriangles.Length, sizeof(int));
        _terrainTriangleBuffer.SetData(terrainTriangles);

        _terrainTriangleCount = terrainTriangles.Length / 3;

        _computeShader.SetBuffer(_kernel, "_TerrainVertices", _terrainVertexBuffer);
        _computeShader.SetBuffer(_kernel, "_TerrainTriangles", _terrainTriangleBuffer);

        // Grass data for RenderPrimitives.
        Vector3[] grassVertices = _grassMesh.vertices;
        _grassVertexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, grassVertices.Length, sizeof(float) * 3);
        _grassVertexBuffer.SetData(grassVertices);

        int[] grassTriangles = _grassMesh.triangles;
        _grassTriangleBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, grassTriangles.Length, sizeof(int));
        _grassTriangleBuffer.SetData(grassTriangles);

        Vector2[] grassUVs = _grassMesh.uv;
        _grassUVBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, grassUVs.Length, sizeof(float) * 2);
        _grassUVBuffer.SetData(grassUVs);

        // Set up buffer for the grass blade transformation matrices.
        _transformMatrixBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, _terrainTriangleCount, sizeof(float) * 16);
        _computeShader.SetBuffer(_kernel, "_TransformMatrices", _transformMatrixBuffer);

        // Set bounds.
        _bounds = _terrainMesh.bounds;
        _bounds.center += transform.position;
        _bounds.Expand(_maxBladeHeight);

        // Bind buffers to a MaterialPropertyBlock which will be used for the draw call.
        _properties = new MaterialPropertyBlock();
        _properties.SetBuffer("_TransformMatrices", _transformMatrixBuffer);
        _properties.SetBuffer("_Positions", _grassVertexBuffer);
        _properties.SetBuffer("_UVs", _grassUVBuffer);

        RunComputeShader();
    }

    private void Update()
    {
        Graphics.DrawProcedural(_grassMaterial, _bounds, MeshTopology.Triangles, _grassTriangleBuffer, _grassTriangleBuffer.count,
            instanceCount: _terrainTriangleCount,
            properties: _properties,
            castShadows: _castShadows,
            receiveShadows: _receiveShadows);
    }

    private void OnDestroy()
    {
        _terrainTriangleBuffer.Dispose();
        _terrainVertexBuffer.Dispose();
        _transformMatrixBuffer.Dispose();

        _grassTriangleBuffer.Dispose();
        _grassVertexBuffer.Dispose();
        _grassUVBuffer.Dispose();
    }
    #endregion

    private void RunComputeShader()
    {
        // Bind variables to the compute shader.
        _computeShader.SetMatrix("_TerrainObjectToWorld", transform.localToWorldMatrix);
        _computeShader.SetInt("_TerrainTriangleCount", _terrainTriangleCount);
        _computeShader.SetFloat("_MinBladeHeight", _minBladeHeight);
        _computeShader.SetFloat("_MaxBladeHeight", _maxBladeHeight);
        _computeShader.SetFloat("_MinOffset", _minOffset);
        _computeShader.SetFloat("_MaxOffset", _maxOffset);
        _computeShader.SetFloat("_Scale", _scale);

        // Run the compute shader's kernel function.
        _computeShader.GetKernelThreadGroupSizes(_kernel, out uint threadGroupSize, out _, out _);
        int threadGroups = Mathf.CeilToInt((float)_terrainTriangleCount / threadGroupSize);
        _computeShader.Dispatch(_kernel, threadGroups, 1, 1);
    }
}
