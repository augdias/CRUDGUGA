package com.crudguga.backend.controller;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import static com.crudguga.backend.config.ApiPaths.ROLE_ADMIN;
import static com.crudguga.backend.config.ApiPaths.USUARIOS;
import static com.crudguga.backend.config.ApiPaths.USUARIOS_ID;
import com.crudguga.backend.dto.UsuarioRequestDTO;
import com.crudguga.backend.entity.Usuario;
import com.crudguga.backend.repository.UsuarioRepository;
import com.fasterxml.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
class UsuarioControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setup() {
        usuarioRepository.deleteAll();
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveCriarUsuarioComSucesso() throws Exception {
        UsuarioRequestDTO request = new UsuarioRequestDTO("Guga", "123456");

        mockMvc.perform(post(USUARIOS)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
            .andExpect(header().string("Location", org.hamcrest.Matchers.matchesRegex(USUARIOS + "/\\d+")))
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.nome").value("Guga"));

        assertThat(usuarioRepository.findAll()).hasSize(1);
        Usuario usuario = usuarioRepository.findAll().get(0);
        assertThat(usuario.getNome()).isEqualTo("Guga");
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveRetornar400QuandoNomeOuSenhaVazios() throws Exception {
        UsuarioRequestDTO request = new UsuarioRequestDTO("", "");

        mockMvc.perform(post(USUARIOS)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.erro").value("Erro de validacao"))
                .andExpect(jsonPath("$.mensagem").isNotEmpty())
                .andExpect(jsonPath("$.caminho").value(USUARIOS));
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveRetornar400QuandoNomeOuSenhaComEspacos() throws Exception {
        UsuarioRequestDTO request = new UsuarioRequestDTO("   ", "   ");

        mockMvc.perform(post(USUARIOS)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.erro").value("Erro de validacao"))
                .andExpect(jsonPath("$.mensagem").isNotEmpty())
                .andExpect(jsonPath("$.caminho").value(USUARIOS));
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveListarUsuariosPaginado() throws Exception {
        for (int i = 1; i <= 5; i++) {
            Usuario usuario = new Usuario();
            usuario.setNome("Usuario" + i);
            usuario.setSenha("senha" + i);
            usuarioRepository.save(usuario);
        }

        mockMvc.perform(get(USUARIOS)
                        .param("page", "0")
                        .param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
            .andExpect(jsonPath("$.content.length()").value(2))
                .andExpect(jsonPath("$.totalElements").value(5))
                .andExpect(jsonPath("$.size").value(2))
                .andExpect(jsonPath("$.number").value(0));
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveListarUsuariosFiltrandoPorNome() throws Exception {
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

        mockMvc.perform(get(USUARIOS)
                        .param("page", "0")
                        .param("size", "10")
                        .param("nome", "gu"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.content.length()").value(2))
                .andExpect(jsonPath("$.content[0].nome").exists());
    }

            @Test
            @WithMockUser(username = "admin", roles = ROLE_ADMIN)
            void deveListarUsuariosOrdenadosPorNomeAscEDesc() throws Exception {
            Usuario u1 = new Usuario();
            u1.setNome("Carlos");
            u1.setSenha("1");

            Usuario u2 = new Usuario();
            u2.setNome("Ana");
            u2.setSenha("2");

            Usuario u3 = new Usuario();
            u3.setNome("Bruno");
            u3.setSenha("3");

            usuarioRepository.save(u1);
            usuarioRepository.save(u2);
            usuarioRepository.save(u3);

            // ASC por nome: Ana, Bruno, Carlos
            mockMvc.perform(get(USUARIOS)
                    .param("page", "0")
                    .param("size", "10")
                    .param("sortBy", "nome")
                    .param("direction", "asc"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].nome").value("Ana"))
                .andExpect(jsonPath("$.content[1].nome").value("Bruno"))
                .andExpect(jsonPath("$.content[2].nome").value("Carlos"));

            // DESC por nome: Carlos, Bruno, Ana
            mockMvc.perform(get(USUARIOS)
                    .param("page", "0")
                    .param("size", "10")
                    .param("sortBy", "nome")
                    .param("direction", "desc"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].nome").value("Carlos"))
                .andExpect(jsonPath("$.content[1].nome").value("Bruno"))
                .andExpect(jsonPath("$.content[2].nome").value("Ana"));
            }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveBuscarUsuarioPorIdComSucesso() throws Exception {
        Usuario usuario = new Usuario();
        usuario.setNome("Joao");
        usuario.setSenha("123456");
        usuario = usuarioRepository.save(usuario);

        mockMvc.perform(get(USUARIOS_ID, usuario.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(usuario.getId()))
                .andExpect(jsonPath("$.nome").value("Joao"));
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveRetornar404QuandoBuscarUsuarioInexistente() throws Exception {
        mockMvc.perform(get(USUARIOS_ID, 9999L))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveAtualizarUsuarioComSucesso() throws Exception {
        Usuario usuario = new Usuario();
        usuario.setNome("Antigo");
        usuario.setSenha("123");
        usuario = usuarioRepository.save(usuario);

        UsuarioRequestDTO request = new UsuarioRequestDTO("NovoNome", "novaSenha");

        mockMvc.perform(put(USUARIOS_ID, usuario.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(usuario.getId()))
                .andExpect(jsonPath("$.nome").value("NovoNome"));

        Usuario atualizado = usuarioRepository.findById(usuario.getId()).orElseThrow();
        assertThat(atualizado.getNome()).isEqualTo("NovoNome");
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveRetornar400AoAtualizarComDadosInvalidos() throws Exception {
        Usuario usuario = new Usuario();
        usuario.setNome("Valido");
        usuario.setSenha("123");
        usuario = usuarioRepository.save(usuario);

        UsuarioRequestDTO request = new UsuarioRequestDTO("", "");

        mockMvc.perform(put(USUARIOS_ID, usuario.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.erro").value("Erro de validacao"))
                .andExpect(jsonPath("$.mensagem").isNotEmpty())
                .andExpect(jsonPath("$.caminho").value(USUARIOS + "/" + usuario.getId()));
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveDeletarUsuarioComSucesso() throws Exception {
        Usuario usuario = new Usuario();
        usuario.setNome("ParaDeletar");
        usuario.setSenha("123");
        usuario = usuarioRepository.save(usuario);

        mockMvc.perform(delete(USUARIOS_ID, usuario.getId()))
                .andExpect(status().isNoContent());

        assertThat(usuarioRepository.existsById(usuario.getId())).isFalse();
    }

    @Test
    @WithMockUser(username = "admin", roles = ROLE_ADMIN)
    void deveRetornar404AoDeletarUsuarioInexistente() throws Exception {
        mockMvc.perform(delete(USUARIOS_ID, 9999L))
                .andExpect(status().isNotFound());
    }
}
