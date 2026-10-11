// Alteração de foto escolhida na tela, aplicada só quando o registro é salvo
sealed class PhotoChange {
  const PhotoChange();
}

// Foto nova (câmera ou galeria), ainda no arquivo temporário do seletor
class PhotoPicked extends PhotoChange {
  final String path;
  const PhotoPicked(this.path);
}

// Usuário pediu para tirar a foto atual
class PhotoRemoved extends PhotoChange {
  const PhotoRemoved();
}
