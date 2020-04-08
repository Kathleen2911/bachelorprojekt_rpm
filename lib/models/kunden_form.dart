class KundenForm {
  String _kennzeichen;
  String _vl;
  String _vr;
  String _hl;
  String _hr;

  KundenForm(this._kennzeichen, this._vl, this._vr, this._hl, this._hr);

  String toParams() =>
      "?kennzeichen=$_kennzeichen&vl=$_vl&vr=$_vr&hl=$_hl&hr=$_hr";
}
