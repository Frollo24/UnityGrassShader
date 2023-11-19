using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityGrassShader
{
    public class AppManager : MonoBehaviour
    {
        [SerializeField] private GameObject _editor;

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
            _editor.active = !_editor.active;
        }
    }
}
