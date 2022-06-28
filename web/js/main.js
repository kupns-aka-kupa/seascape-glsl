import * as THREE from "three";
import {GLTFLoader} from 'three/examples/jsm/loaders/GLTFLoader.js';

const camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 10);
camera.position.z = 5;
const loader = new GLTFLoader();
const scene = new THREE.Scene();

const aLight = new THREE.DirectionalLight(0xffffff, 1.5);
aLight.position.setScalar(10);
scene.add(aLight, new THREE.AmbientLight(0xffffff, 0.5));
loader.load(
  'theme.gltf',
  function (gltf) {
    scene.add(gltf.scene);
  },
  function (xhr) {
    console.log((xhr.loaded / xhr.total * 100) + '% loaded');
  },
  function (error) {
    console.error(error);
  }
);

const renderer = new THREE.WebGLRenderer({antialias: true});
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setAnimationLoop(animation);
document.body.appendChild(renderer.domElement);

function animation() {
  renderer.render(scene, camera);
}
