using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityGrassShader
{
    public enum BuildOption
    {
        None = 0,
        WallpaperEngine = 1,
        StandaloneApp = 2,
        WebGLApp = 3,
    }

    public class AppManager : MonoBehaviour
    {
        [SerializeField] private BuildOption _buildOption = BuildOption.StandaloneApp;
        [SerializeField] private GameObject _editor;

        private void Start()
        {
            _editor.SetActive(_buildOption != BuildOption.WallpaperEngine);
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape))
                Application.Quit();

            if (Input.GetKeyDown(KeyCode.F11))
                Screen.fullScreen = !Screen.fullScreen;

            if (Input.GetKeyDown(KeyCode.E))
                ToggleEditor();
        }

        private void ToggleEditor()
        {
            _editor.SetActive(!_editor.activeSelf);
        }
    }
}
