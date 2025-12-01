package com.crudguga.backend.service;

import com.crudguga.backend.dto.UsuarioDTO;
import com.crudguga.backend.dto.UsuarioRequestDTO;
import com.crudguga.backend.entity.Usuario;
import com.crudguga.backend.repository.UsuarioRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UsuarioService {

    private final UsuarioRepository repository;

    public UsuarioService(UsuarioRepository repository) {
        this.repository = repository;
    }

    public UsuarioDTO criar(UsuarioRequestDTO dto) {
        Usuario usuario = new Usuario();
        usuario.setNome(dto.getNome());
        usuario.setSenha(dto.getSenha());
        Usuario salvo = repository.save(usuario);
        return new UsuarioDTO(salvo.getId(), salvo.getNome());
    }

    public List<UsuarioDTO> listar() {
        return repository.findAll()
                .stream()
                .map(u -> new UsuarioDTO(u.getId(), u.getNome()))
                .toList();
    }

    public Page<UsuarioDTO> listarPaginado(Pageable pageable) {
        return repository.findAll(pageable)
                .map(u -> new UsuarioDTO(u.getId(), u.getNome()));
    }

    public Page<UsuarioDTO> listarPaginadoPorNome(String nome, Pageable pageable) {
        return repository.findByNomeContainingIgnoreCase(nome, pageable)
                .map(u -> new UsuarioDTO(u.getId(), u.getNome()));
    }

    public Optional<UsuarioDTO> buscarPorId(Long id) {
        return repository.findById(id)
                .map(u -> new UsuarioDTO(u.getId(), u.getNome()));
    }

    public Optional<UsuarioDTO> atualizar(Long id, UsuarioRequestDTO dto) {
        return repository.findById(id)
                .map(usuario -> {
                    usuario.setNome(dto.getNome());
                    if (dto.getSenha() != null && !dto.getSenha().isBlank()) {
                        usuario.setSenha(dto.getSenha());
                    }
                    Usuario salvo = repository.save(usuario);
                    return new UsuarioDTO(salvo.getId(), salvo.getNome());
                });
    }

    public boolean deletar(Long id) {
        if (!repository.existsById(id)) {
            return false;
        }
        repository.deleteById(id);
        return true;
    }
}
