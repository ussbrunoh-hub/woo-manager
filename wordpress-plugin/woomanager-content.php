<?php
/**
 * Plugin Name: WooManager Content API
 * Description: Endpoint REST dédié et sécurisé pour l'app WooManager (articles et pages). Authentification par mot de passe d'application obligatoire.
 * Version: 1.0
 * Author: WooManager
 */

if (!defined('ABSPATH')) {
    exit;
}

add_action('rest_api_init', function () {
    register_rest_route('woomanager/v1', '/content', [
        'methods'  => 'GET',
        'callback' => 'woomanager_content_list',
        'permission_callback' => function () {
            // Exige un utilisateur authentifié (mot de passe d'application) avec droits de lecture.
            return is_user_logged_in() && current_user_can('edit_posts');
        },
        'args' => [
            'type' => [
                'required' => false,
                'default' => 'posts',
                'enum' => ['posts', 'pages'],
            ],
            'per_page' => [
                'required' => false,
                'default' => 50,
                'sanitize_callback' => function ($v) { return max(1, min(100, absint($v))); },
            ],
            'page' => [
                'required' => false,
                'default' => 1,
                'sanitize_callback' => function ($v) { return max(1, absint($v)); },
            ],
        ],
    ]);
});

function woomanager_content_list(WP_REST_Request $request) {
    $type = $request->get_param('type');
    $post_type = $type === 'pages' ? 'page' : 'post';
    $per_page = (int) $request->get_param('per_page');
    $page = (int) $request->get_param('page');

    $query = new WP_Query([
        'post_type'      => $post_type,
        'post_status'    => ['publish', 'draft', 'pending', 'private', 'future'],
        'posts_per_page' => $per_page,
        'paged'          => $page,
        'orderby'        => 'date',
        'order'          => 'DESC',
        'no_found_rows'  => true,
    ]);

    $items = [];
    foreach ($query->posts as $post) {
        $items[] = [
            'id'     => (int) $post->ID,
            'title'  => ['rendered' => get_the_title($post)],
            'excerpt' => ['rendered' => wp_trim_words(strip_tags(get_the_excerpt($post)), 40)],
            'status' => $post->post_status,
            'link'   => get_permalink($post),
            'date'   => $post->post_date_gmt,
            'type'   => $post_type,
        ];
    }

    return rest_ensure_response($items);
}
