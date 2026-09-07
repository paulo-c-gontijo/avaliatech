import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

class AvaliaTechException implements Exception {
  AvaliaTechException(this.message);
  final String message;
  @override String toString() => message;
}

// Repositório local de demonstração. Não é um servidor de autenticação nem
// sincroniza dispositivos. Toda escrita passa pelas regras de domínio abaixo.
class AvaliationStore extends ChangeNotifier {
  AvaliationStore(this.preferences);
  final SharedPreferences preferences;
  final List<Usuario> usuarios = [];
  final List<Turma> turmas = [];
  final List<ConviteTurma> convites = [];
  final List<Questao> questoes = [];
  final List<Questionario> _unused = []; // Placeholder removed below.
