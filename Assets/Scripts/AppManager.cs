using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityGrassShader
{
    public class AppManager : MonoBehaviour
    {
        [SerializeField] private bool _isWallpaperBuild; // TODO: expand with other building options
        [SerializeField] private GameObject _editor;

        private void Start()
        {
            _editor.SetActive(!_isWallpaperBuild);
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
