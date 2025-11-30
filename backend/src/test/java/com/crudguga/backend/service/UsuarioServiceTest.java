package com.crudguga.backend.service;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import com.crudguga.backend.dto.UsuarioDTO;
import com.crudguga.backend.dto.UsuarioRequestDTO;
import com.crudguga.backend.entity.Usuario;
import com.crudguga.backend.repository.UsuarioRepository;

@SpringBootTest
class UsuarioServiceTest {

    @Autowired
    private UsuarioService usuarioService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @BeforeEach
    void setup() {
        usuarioRepository.deleteAll();
    }

    @Test
    void deveCriarUsuario() {
        UsuarioRequestDTO request = new UsuarioRequestDTO("Guga", "123456");

        UsuarioDTO criado = usuarioService.criar(request);

        assertThat(criado.getId()).isNotNull();
        assertThat(criado.getNome()).isEqualTo("Guga");

        List<Usuario> todos = usuarioRepository.findAll();
        assertThat(todos).hasSize(1);
        assertThat(todos.get(0).getNome()).isEqualTo("Guga");
    }

    @Test
    void deveListarUsuarios() {
        Usuario u1 = new Usuario();
        u1.setNome("A");
        u1.setSenha("1");
        Usuario u2 = new Usuario();
        u2.setNome("B");
        u2.setSenha("2");
        usuarioRepository.save(u1);
        usuarioRepository.save(u2);

        List<UsuarioDTO> lista = usuarioService.listar();

        assertThat(lista).hasSize(2);
        assertThat(lista).extracting(UsuarioDTO::getNome).containsExactlyInAnyOrder("A", "B");
    }

    @Test
    void deveListarUsuariosPaginado() {
        for (int i = 1; i <= 5; i++) {
            Usuario u = new Usuario();
            u.setNome("Usuario" + i);
            u.setSenha("senha" + i);
            usuarioRepository.save(u);
        }

        PageRequest pageRequest = PageRequest.of(0, 2);

        Page<UsuarioDTO> pagina = usuarioService.listarPaginado(pageRequest);

        assertThat(pagina.getContent()).hasSize(2);
        assertThat(pagina.getTotalElements()).isEqualTo(5);
        assertThat(pagina.getSize()).isEqualTo(2);
        assertThat(pagina.getNumber()).isEqualTo(0);
    }

    @Test
    void deveListarUsuariosPaginadoFiltrandoPorNome() {
        Usuario u1 = new Usuario();
        u1.setNome("Gustavo");
        u1.setSenha("1");

        Usuario u2 = new Usuario();
        u2.setNome("Guga");
        u2.setSenha("2");

        Usuario u3 = new Usuario();
        u3.setNome("Outro");
        u3.setSenha("3");

        usuarioRepository.save(u1);
        usuarioRepository.save(u2);
        usuarioRepository.save(u3);

        PageRequest pageRequest = PageRequest.of(0, 10);

        Page<UsuarioDTO> pagina = usuarioService.listarPaginadoPorNome("gu", pageRequest);

        assertThat(pagina.getTotalElements()).isEqualTo(2);
        assertThat(pagina.getContent()).extracting(UsuarioDTO::getNome)
                .containsExactlyInAnyOrder("Gustavo", "Guga");
    }

    @Test
    void deveBuscarPorIdQuandoExistente() {
        Usuario usuario = new Usuario();
        usuario.setNome("Joao");
        usuario.setSenha("123");
        usuario = usuarioRepository.save(usuario);

        Optional<UsuarioDTO> encontrado = usuarioService.buscarPorId(usuario.getId());

        assertThat(encontrado).isPresent();
        assertThat(encontrado.get().getNome()).isEqualTo("Joao");
    }

    @Test
    void deveRetornarEmptyAoBuscarIdInexistente() {
        Optional<UsuarioDTO> encontrado = usuarioService.buscarPorId(9999L);
        assertThat(encontrado).isEmpty();
    }

    @Test
    void deveAtualizarUsuarioExistente() {
        Usuario usuario = new Usuario();
        usuario.setNome("Antigo");
        usuario.setSenha("123");
        usuario = usuarioRepository.save(usuario);

        UsuarioRequestDTO request = new UsuarioRequestDTO("Novo", "novaSenha");

        Optional<UsuarioDTO> atualizadoOpt = usuarioService.atualizar(usuario.getId(), request);

        assertThat(atualizadoOpt).isPresent();
        UsuarioDTO atualizado = atualizadoOpt.get();
        assertThat(atualizado.getNome()).isEqualTo("Novo");

        Usuario noBanco = usuarioRepository.findById(usuario.getId()).orElseThrow();
        assertThat(noBanco.getNome()).isEqualTo("Novo");
    }

    @Test
    void deveManterSenhaQuandoNaoInformadaNaAtualizacao() {
        Usuario usuario = new Usuario();
        usuario.setNome("NomeInicial");
        usuario.setSenha("senhaOriginal");
        usuario = usuarioRepository.save(usuario);

        UsuarioRequestDTO request = new UsuarioRequestDTO("NomeAlterado", null);

        Optional<UsuarioDTO> atualizadoOpt = usuarioService.atualizar(usuario.getId(), request);

        assertThat(atualizadoOpt).isPresent();

        Usuario noBanco = usuarioRepository.findById(usuario.getId()).orElseThrow();
        assertThat(noBanco.getNome()).isEqualTo("NomeAlterado");
        assertThat(noBanco.getSenha()).isEqualTo("senhaOriginal");
    }

    @Test
    void naoDeveAtualizarUsuarioInexistente() {
        UsuarioRequestDTO request = new UsuarioRequestDTO("Novo", "novaSenha");

        Optional<UsuarioDTO> atualizado = usuarioService.atualizar(9999L, request);

        assertThat(atualizado).isEmpty();
    }

    @Test
    void deveDeletarUsuarioExistente() {
        Usuario usuario = new Usuario();
        usuario.setNome("ParaDeletar");
        usuario.setSenha("123");
        usuario = usuarioRepository.save(usuario);

        boolean deletado = usuarioService.deletar(usuario.getId());

        assertThat(deletado).isTrue();
        assertThat(usuarioRepository.existsById(usuario.getId())).isFalse();
    }

    @Test
    void naoDeveDeletarUsuarioInexistente() {
        boolean deletado = usuarioService.deletar(9999L);
        assertThat(deletado).isFalse();
    }
}
