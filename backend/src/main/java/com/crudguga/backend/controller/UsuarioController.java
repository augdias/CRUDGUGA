package com.crudguga.backend.controller;

import com.crudguga.backend.dto.UsuarioDTO;
import com.crudguga.backend.dto.UsuarioRequestDTO;
import com.crudguga.backend.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;

import static com.crudguga.backend.config.ApiPaths.USUARIOS;
import static com.crudguga.backend.config.ApiPaths.USUARIOS_ID;

@RestController
@RequestMapping(USUARIOS)
public class UsuarioController {

    private final UsuarioService service;

    public UsuarioController(UsuarioService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<UsuarioDTO> criar(@RequestBody @Valid UsuarioRequestDTO dto) {
        UsuarioDTO criado = service.criar(dto);
        URI location = URI.create(USUARIOS + "/" + criado.getId());
        return ResponseEntity.created(location).body(criado);
    }

    @GetMapping
    public ResponseEntity<Page<UsuarioDTO>> listar(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "nome") String sortBy,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) String nome) {

        Sort sort = "desc".equalsIgnoreCase(direction)
                ? Sort.by(sortBy).descending()
                : Sort.by(sortBy).ascending();

        Pageable pageable = PageRequest.of(page, size, sort);

        Page<UsuarioDTO> usuarios;
        if (nome != null && !nome.isBlank()) {
            usuarios = service.listarPaginadoPorNome(nome, pageable);
        } else {
            usuarios = service.listarPaginado(pageable);
        }

        return ResponseEntity.ok(usuarios);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UsuarioDTO> buscarPorId(@PathVariable Long id) {
        return service.buscarPorId(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<UsuarioDTO> atualizar(@PathVariable Long id,
                                                @RequestBody @Valid UsuarioRequestDTO dto) {
        return service.atualizar(id, dto)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        boolean removido = service.deletar(id);
        if (!removido) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.noContent().build();
    }
}
