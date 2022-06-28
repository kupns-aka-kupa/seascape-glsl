function main() {
  const canvas = document.querySelector('#c');
  const renderer = new THREE.WebGLRenderer({canvas});
  const loader = new THREE.FileLoader();

  renderer.autoClearColor = false;

  const camera = new THREE.OrthographicCamera(
    -1, // left
    1, // right
    1, // top
    -1, // bottom
    -1, // near,
    1, // far
  );
  const scene = new THREE.Scene();
  const plane = new THREE.PlaneBufferGeometry(2, 2);
  const uniforms = {
    iTime: {value: 0},
    iResolution: {value: new THREE.Vector3()},
    iMouse: {value: new THREE.Vector2()},
  };
  const scripts = Array.from(document.getElementsByTagName('script'))
    .filter(s => s.className === 'chunk');

  for (let i = 0; i < scripts.length; i++) {
    let filename = Array.from(scripts[i].src.split('/')).at(-1);
    loader.load(scripts[i].src,
      function (figures) {
        THREE.ShaderChunk[filename] = figures;
      }, console.debug, console.error);
  }

  loader.load(document.getElementById('fragmentShader').src,
    function (s) {
      const material = new THREE.ShaderMaterial({
        fragmentShader: s,
        uniforms,
      });
      scene.add(new THREE.Mesh(plane, material));
    }, null, console.error);

  loader.load(document.getElementById('vertexShader').src,
    function (s) {
      const material = new THREE.ShaderMaterial({
        vertexShader: s,
        uniforms,
      });
      scene.add(new THREE.Mesh(plane, material));
    }, null, console.error);

  function resizeRendererToDisplaySize(renderer) {
    const canvas = renderer.domElement;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    const needResize = canvas.width !== width || canvas.height !== height;
    if (needResize) {
      renderer.setSize(width, height, false);
    }
    return needResize;
  }

  document.onmousemove = function (e) {
    uniforms.iMouse.value.x = e.pageX / window.innerWidth;
    uniforms.iMouse.value.y = e.pageY / window.innerHeight;
  }

  function render(time) {
    time *= 0.001;  // convert to seconds

    resizeRendererToDisplaySize(renderer);

    const canvas = renderer.domElement;
    uniforms.iResolution.value.set(canvas.width, canvas.height, 1);
    uniforms.iTime.value = time;

    renderer.render(scene, camera);

    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);
}

main();
